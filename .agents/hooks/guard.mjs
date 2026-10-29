import { existsSync, readFileSync } from "node:fs";
import { isAbsolute, relative, resolve } from "node:path";
import { root } from "../../scripts/lib.mjs";

const testHomes = /^(?:Tools\/Tests\/|App\/UITests\/|App\/PerformanceTests\/|App\/TestSupport\/)/;
const docHomes = /^(?:docs\/agents\/|gui\/|GUI\.md$|\.scratch\/|\.github\/)/;
const checkFiles = [
  /(?:^|\/)\.swiftlint\.yml$/,
  /^\.swift-format$/,
  /^policy\.json$/,
  /^performance\.json$/,
  /^mise\.toml$/,
  /^toolchain\.json$/,
  /^Tuist\/ProjectDescriptionHelpers\/BuildSettings\.swift$/,
  /^scripts\/(?:verify|contract|doctor|lib|test-hooks|comments|gui)\.mjs$/,
  /^Tools\/Sources\//,
  /^\.githooks\//,
  /^\.agents\/hooks\//,
  /^\.claude\//,
  /^\.codex\//,
  /^\.github\/workflows\//,
];

const forCodex = process.argv.includes("--codex");
const input = JSON.parse(readFileSync(0, "utf8"));
const tool = input.tool_input ?? {};
const command =
  typeof tool === "string"
    ? tool
    : ([tool.command, tool.cmd, tool.patch, tool.input].find((value) => typeof value === "string") ?? "");
const isPatch = /^\*\*\* Begin Patch/m.test(command);
const toolContent = [tool.content, tool.new_string, ...(tool.edits ?? []).map((edit) => edit.new_string)]
  .filter((value) => typeof value === "string")
  .join("\n");

function patchTargets(patch) {
  return patch
    .split(/^(?=\*\*\* (?:Add|Update|Delete) File: )/m)
    .flatMap((section) => {
      const header = section.match(/^\*\*\* (?:Add|Update|Delete) File: (.+)$/m);
      const moved = section.match(/^\*\*\* Move to: (.+)$/m);
      return [header?.[1], moved?.[1]].filter(Boolean).map((path) => ({ path: path.trim(), content: section }));
    });
}

const targets = [
  ...[tool.file_path, tool.path, tool.notebook_path]
    .filter((path) => typeof path === "string")
    .map((path) => ({ path, content: toolContent })),
  ...(isPatch ? patchTargets(command) : []),
]
  .map(({ path, content }) => ({
    path: relative(root, resolve(input.cwd ?? root, path)).replaceAll("\\", "/"),
    content,
  }))
  .filter(({ path }) => path !== ".." && !path.startsWith("../") && !isAbsolute(path));

function decide(decision, reason) {
  const needsPerson = forCodex && decision === "ask";
  const permissionDecision = needsPerson ? "deny" : decision;
  const permissionDecisionReason = needsPerson
    ? `A person must approve this first. ${reason} Ask them to approve it or to make the change.`
    : reason;
  console.log(
    JSON.stringify({
      hookSpecificOutput: { hookEventName: "PreToolUse", permissionDecision, permissionDecisionReason },
    }),
  );
  process.exit(0);
}

function editDecision({ path, content }) {
  const isNew = !existsSync(resolve(root, path));
  if (/(?:^|\/)(?:\.build|\.swiftpm|Derived|DerivedData)\/|\.xcodeproj(?:\/|$)|\.xcworkspace(?:\/|$)|^\.git\//.test(path)) {
    return ["deny", `${path} is generated. Change Project.swift or Tuist/ProjectDescriptionHelpers, then run mise run generate.`];
  }
  if (path === "gui/theme.md") {
    return ["deny", "gui/theme.md is generated. Change a token in Packages/UI/Sources/DesignSystem/Tokens/, then run mise run gui."];
  }
  if (/^\.(?:agents|claude)\/skills\/|^skills-lock\.json$/.test(path)) {
    return ["deny", "Vendored skills change only through the skills CLI: mise run update:skills, or npx skills add."];
  }
  if (/(?:^|\/)Package\.resolved$/.test(path)) {
    return ["deny", "Package.resolved belongs to SwiftPM. Change the exact version in Package.swift and run swift package resolve."];
  }
  if (isNew && /\.mdx?$/.test(path) && !docHomes.test(path)) {
    return ["deny", "Guides live in docs/agents/. Put plans, notes, and evidence in .scratch/, which Git ignores."];
  }
  const looksLikeTest = /Tests?\.swift$/.test(path) || /^\+?\s*import (?:Testing|XCTest)\b/m.test(content);
  if (isNew && path.endsWith(".swift") && looksLikeTest && !testHomes.test(path)) {
    return [
      "deny",
      "App code has no unit tests. Verify behavior end to end with a journey in App/UITests/.",
    ];
  }
  if (checkFiles.some((pattern) => pattern.test(path))) {
    return ["ask", `${path} is part of the checks. A person approves changes that loosen a rule, threshold, or hook.`];
  }
  return undefined;
}

const hookBypass = "Fix the failing check instead. A person can bypass the hooks if they decide to.";
const optionValue = String.raw`(?:"[^"]*"|'[^']*'|\S+)`;
const gitGlobalOptions = new RegExp(
  String.raw`\bgit((?:\s+(?:-C|-c|--git-dir|--work-tree|--namespace)\s*${optionValue}|\s+--[\w-]+(?:=${optionValue})?|\s+-[pP])*)\s+`,
);
const configRead = /\bgit\s+config\b.*\s(?:--get(?:-all|-regexp)?|--list|-l|get)(?:\s|$)/;

const commandRules = [
  {
    test: (part) =>
      /\bgit\s+(?:commit|merge|rebase|am|push|cherry-pick)\b.*\s--no-verify(?:\s|$)/.test(part) ||
      /\bgit\s+commit\b.*\s-n(?:\s|$)/.test(part),
    decision: "deny",
    reason: `--no-verify skips the Git hooks. ${hookBypass}`,
  },
  {
    test: (part, raw) => /core\.hooksPath/i.test(raw) && !configRead.test(part),
    decision: "deny",
    reason: `Changing core.hooksPath disables the Git hooks. ${hookBypass}`,
  },
  {
    test: (part) => /\bgit\s+push\b.*\s(?:--force(?![-\w])|-[a-zA-Z]*f[a-zA-Z]*\b|\+\S)/.test(part),
    decision: "deny",
    reason: "A force push can destroy commits on the remote. Use --force-with-lease when a person asked for a rewrite.",
  },
  {
    test: (part) => /\bgit\s+push\b.*--force-with-lease/.test(part),
    decision: "ask",
    reason: "This rewrites history on the remote. A person confirms history rewrites.",
  },
  {
    test: (part) =>
      /\bgit\s+(?:reset\s+--hard|clean\s+-[a-zA-Z]*f|checkout\s+--\s+\.|restore\s+(?:--worktree\s+)?\.)/.test(part),
    decision: "ask",
    reason: "This discards uncommitted work. A person confirms destructive Git commands.",
  },
  {
    test: (part) => /\brm\s+(?:-[a-zA-Z]+\s+)+(?:--\s+)?["']?(?:\S*\/)?\.git["']?(?:\s|\/|$)/.test(part),
    decision: "deny",
    reason: "Deleting .git destroys the repository history.",
  },
  {
    test: (part) =>
      /(?:SWIFT|GCC)_TREAT_WARNINGS_AS_ERRORS=NO|SWIFT_SUPPRESS_WARNINGS=YES|GCC_WARN_INHIBIT_ALL_WARNINGS=YES|-suppress-warnings|SWIFT_STRICT_CONCURRENCY=(?:minimal|targeted)|SWIFT_VERSION=[45]\b|-swift-version\s+[45]\b/.test(
        part,
      ),
    decision: "deny",
    reason: "Do not silence warnings or relax the language mode. Fix the diagnostic at its source.",
  },
  {
    test: (part) =>
      /\bbrew\s+(?:install|upgrade|reinstall)\b.*\b(?:node|swiftlint|swiftformat|swift-format|tuist|periphery|xcodegen)\b/.test(
        part,
      ),
    decision: "deny",
    reason: "Tools are pinned in mise.toml. Run mise install.",
  },
  {
    test: (part) => /\bxcrun\s+simctl\s+(?:erase|delete)\b/.test(part),
    decision: "ask",
    reason: "This erases or deletes simulators that may hold a person's data. A person confirms it.",
  },
];

const parts = input.tool_name === "apply_patch"
  ? []
  : command
      .split(/\n|;|&&|\|\||\|/)
      .map((raw) => raw.trim())
      .map((raw) => ({ raw, part: raw.replace(gitGlobalOptions, "git ") }));
const decisions = [
  ...targets.map(editDecision).filter(Boolean),
  ...commandRules
    .filter((rule) => parts.some(({ raw, part }) => rule.test(part, raw)))
    .map((rule) => [rule.decision, rule.reason]),
];
const decision = decisions.find(([kind]) => kind === "deny") ?? decisions[0];
if (decision) decide(...decision);
