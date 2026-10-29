import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { hashCommentLines, javaScriptCommentLines } from "./comments.mjs";
import { root } from "./lib.mjs";

function toolName(toolInput) {
  if (toolInput.file_path) return "Write";
  return /^\*\*\* Begin Patch/.test(toolInput.command) ? "apply_patch" : "Bash";
}

function guard(toolInput, ...flags) {
  const result = spawnSync(process.execPath, [".agents/hooks/guard.mjs", ...flags], {
    cwd: root,
    encoding: "utf8",
    input: JSON.stringify({
      hook_event_name: "PreToolUse",
      cwd: root,
      tool_name: toolName(toolInput),
      tool_input: toolInput,
    }),
  });
  assert.equal(result.status, 0, result.stderr);
  return result.stdout ? JSON.parse(result.stdout).hookSpecificOutput.permissionDecision : "allow";
}

const cases = [
  [{ command: "git commit --no-verify -m 'feat: x'" }, "deny"],
  [{ command: "git commit -n -m 'feat: x'" }, "deny"],
  [{ command: "git push --no-verify" }, "deny"],
  [{ command: "git config core.hooksPath /dev/null" }, "deny"],
  [{ command: "git push --force origin main" }, "deny"],
  [{ command: "git push origin main -f" }, "deny"],
  [{ command: "git push --force-with-lease origin topic" }, "ask"],
  [{ command: "git reset --hard HEAD~1" }, "ask"],
  [{ command: "rm -rf .git" }, "deny"],
  [{ command: "xcodebuild build SWIFT_TREAT_WARNINGS_AS_ERRORS=NO" }, "deny"],
  [{ command: "swift build -Xswiftc -suppress-warnings" }, "deny"],
  [{ command: "brew install swiftlint" }, "deny"],
  [{ command: "xcrun simctl erase all" }, "ask"],
  [{ command: "git log -n 5" }, "allow"],
  [{ command: "git push origin fix-f" }, "allow"],
  [{ command: "mise run check" }, "allow"],
  [{ file_path: "Saddle.xcodeproj/project.pbxproj" }, "deny"],
  [{ file_path: "Derived/Sources/TuistBundle+Saddle.swift" }, "deny"],
  [{ file_path: "Tools/Package.resolved" }, "deny"],
  [{ command: "*** Begin Patch\n*** Update File: Tools/Package.resolved\n*** End Patch" }, "deny"],
  [{ file_path: "NEW_PLAN.md" }, "deny"],
  [{ file_path: ".scratch/notes.md" }, "allow"],
  [{ file_path: "docs/agents/NEW_GUIDE.md" }, "allow"],
  [{ file_path: "Packages/UI/Sources/LibraryFeature/LibraryModelTests.swift" }, "deny"],
  [{ file_path: "App/Sources/Probe.swift", content: "import XCTest\n" }, "deny"],
  [{ file_path: "Packages/Core/Tests/DomainTests/NewTests.swift", content: "import Testing\n" }, "deny"],
  [{ file_path: "Tools/Tests/PolicyKitTests/NewRuleTests.swift", content: "import Testing\n" }, "allow"],
  [{ file_path: ".agents/skills/swiftui-pro/SKILL.md" }, "deny"],
  [{ file_path: "skills-lock.json" }, "deny"],
  [{ file_path: "App/UITests/NewJourneyTests.swift", content: "import XCTest\n" }, "allow"],
  [{ file_path: ".swiftlint.yml" }, "ask"],
  [{ file_path: "Packages/UI/Sources/LibraryFeature/.swiftlint.yml" }, "ask"],
  [{ file_path: "policy.json" }, "ask"],
  [{ file_path: "Tuist/ProjectDescriptionHelpers/BuildSettings.swift" }, "ask"],
  [{ file_path: "Tools/Sources/PolicyKit/Rule.swift" }, "ask"],
  [{ file_path: "Packages/UI/Sources/LibraryFeature/LibraryView.swift" }, "allow"],
  [{ file_path: "Project.swift" }, "allow"],
  [{ file_path: join(tmpdir(), "saddle-outside", "NOTES.md") }, "allow"],
  [{ command: "git -C /repo push --force" }, "deny"],
  [{ command: "git -C /repo commit --no-verify -m 'feat: x'" }, "deny"],
  [{ command: "git -c core.hooksPath=/dev/null commit -m 'feat: x'" }, "deny"],
  [{ command: "git config --get core.hooksPath" }, "allow"],
  [{ command: "git config --file .git/config --get core.hooksPath" }, "allow"],
  [{ command: 'git -C "/tmp/my repo" push --force' }, "deny"],
  [{ command: "git -C/repo push --force" }, "deny"],
  [
    {
      command:
        "apply_patch <<'EOF'\n*** Begin Patch\n*** Update File: App/Sources/MainApp.swift\n+let x = 1\n" +
        "*** End Patch\nEOF\ngit push --force origin main",
    },
    "deny",
  ],
  [{ command: "git push -n origin main" }, "allow"],
  [{ command: "git cherry-pick -n abc123" }, "allow"],
  [{ command: 'rm -rf ".git"' }, "deny"],
  [{ command: "rm -rf -- .git" }, "deny"],
  [{ command: "rm -r -f .git" }, "deny"],
  [{ command: "brew install node" }, "deny"],
  [{ command: "*** Begin Patch\n*** Update File: scripts/test-hooks.mjs\n+git push --force\n*** End Patch" }, "ask"],
  [{ command: "*** Begin Patch\n*** Add File: App/Sources/Probe.swift\n+import Testing\n*** End Patch" }, "deny"],
  [
    {
      command:
        "*** Begin Patch\n*** Add File: App/Sources/Feature.swift\n+import SwiftUI\n" +
        "*** Update File: App/UITests/LibraryJourneyTests.swift\n+import XCTest\n*** End Patch",
    },
    "allow",
  ],
];
const codexCases = [
  [{ file_path: ".swiftlint.yml" }, "deny"],
  [{ command: "git reset --hard" }, "deny"],
  [{ file_path: "Packages/UI/Sources/LibraryFeature/LibraryView.swift" }, "allow"],
];
for (const [toolInput, expected] of cases) {
  assert.equal(guard(toolInput), expected, JSON.stringify(toolInput));
}
for (const [toolInput, expected] of codexCases) {
  assert.equal(guard(toolInput, "--codex"), expected, `codex ${JSON.stringify(toolInput)}`);
}

const javaScriptCases = [
  ["const a = 1;\n// note\n", [2]],
  ["const a = 1; /* block */\n", [1]],
  ['const url = "https://example.com";\n', []],
  ["const re = /\\/\\*[\\s\\S]*?\\*\\//g;\n", []],
  ["const t = `a ${ {x: 1}.x } // not a comment`;\n", []],
  ["const t = `a ${b}`; // trailing\n", [1]],
  ["const half = total / 2; const r = (x) => /a\\/b/.test(x);\n", []],
  ["if (ok) /[/*]/.test(value);\n", []],
  ["if (ok) /https?:\\/\\//.test(url);\n", []],
  ["const half = i++ / 2; // note\n", [1]],
  ["const unfinished = 1; /* never closed\n", [1]],
  ["const result = handlers.with(value) / 2; // note\n", [1]],
  ["const items = list.with(0, first); if (ok) /x/.test(items);\n", []],
];
for (const [source, expected] of javaScriptCases) {
  assert.deepEqual(javaScriptCommentLines(source), expected, source);
}
const hashCases = [
  ["#!/bin/sh\nset -eu\n", []],
  ["# note\nkey = 1\n", [1]],
  ['key = "a # b"\n', []],
  ["      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1\n", []],
  ["run: make # build\n", [1]],
  ["echo ok #comment\n", [1]],
  ["value = 1 #comment\n", [1]],
  ['echo "a \\" # b"\n', []],
  ["echo ${#items}\n", []],
];
for (const [source, expected] of hashCases) {
  assert.deepEqual(hashCommentLines(source), expected, source);
}

const directory = mkdtempSync(join(tmpdir(), "saddle-commit-"));
try {
  const message = join(directory, "message");
  const accepts = (text) => {
    writeFileSync(message, `${text}\n`);
    return spawnSync("sh", [join(root, ".githooks/commit-msg"), message]).status === 0;
  };
  for (const text of ["feat: add search", "fix(library): keep favorites", "fixup! feat: add search", "Merge branch 'x'"]) {
    assert.equal(accepts(text), true, text);
  }
  for (const text of ["update stuff", "feat: ", `feat: ${"a".repeat(100)}`, "feat: x\n\nCo-Authored-By: A <a@b.c>"]) {
    assert.equal(accepts(text), false, text);
  }
} finally {
  rmSync(directory, { recursive: true, force: true });
}

console.log(`hook tests: ${cases.length + codexCases.length} guard cases and the commit-msg hook passed`);
