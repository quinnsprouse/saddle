import { existsSync, readFileSync } from "node:fs";
import { isAbsolute, relative, resolve } from "node:path";
import { capture, root } from "../../scripts/lib.mjs";

const policyBinary = resolve(root, ".build/spm/tools/debug/policy");

const input = JSON.parse(readFileSync(0, "utf8"));
const tool = input.tool_input ?? {};
const patch = [tool.command, tool.patch, tool.input].find((value) => typeof value === "string") ?? "";
const files = [
  tool.file_path,
  ...Array.from(patch.matchAll(/^\*\*\* (?:Add|Update) File: (.+)$|^\*\*\* Move to: (.+)$/gm), (match) =>
    (match[1] ?? match[2]).trim(),
  ),
]
  .filter((path) => typeof path === "string" && path.endsWith(".swift"))
  .map((path) => relative(root, resolve(input.cwd ?? root, path)))
  .filter((path) => !path.startsWith("..") && !isAbsolute(path) && existsSync(resolve(root, path)))
  .filter((path) => !/(?:^|\/)(?:\.build|\.scratch|Derived)\//.test(path));

const feedback = [];
for (const path of files) {
  const format = capture("xcrun", ["swift-format", "format", "--in-place", path]);
  if (!format.ok) feedback.push(`swift-format could not format ${path}:\n${format.output}`);
  const lint = capture("swiftlint", ["lint", "--strict", "--quiet", path]);
  if (!lint.ok) feedback.push(`SwiftLint found problems in ${path}:\n${lint.output}`);
  if (existsSync(policyBinary)) {
    const policy = capture(policyBinary, ["--config", "policy.json", path]);
    if (!policy.ok) feedback.push(`Policy found problems in ${path}:\n${policy.output}`);
  }
}

if (feedback.length > 0) {
  const additionalContext = feedback.join("\n\n").replaceAll(`${root}/`, "").slice(0, 4_000);
  console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: "PostToolUse", additionalContext } }));
}
