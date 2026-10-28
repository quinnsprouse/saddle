import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { capture, pinnedTools, root, simulator, toolchain } from "./lib.mjs";

const checks = [];

function check(name, required, fix, probe) {
  try {
    const detail = probe();
    checks.push({ name, required, ok: detail === true, detail: detail === true ? undefined : detail, fix });
  } catch (error) {
    checks.push({ name, required, ok: false, detail: error.message.split("\n")[0], fix });
  }
}

function majorMinor(version) {
  return version.split(".").slice(0, 2).join(".");
}

check("macOS", true, "Update to macOS 26 or newer.", () => {
  const version = capture("sw_vers", ["-productVersion"]).output.trim();
  return Number(version.split(".")[0]) >= 26 || `macOS ${version}`;
});

check(
  "Xcode",
  true,
  `Install Xcode ${toolchain.xcode} and select it with sudo xcode-select -s /Applications/Xcode.app`,
  () => {
    const version = capture("xcodebuild", ["-version"]).output.match(/^Xcode (\S+)/m)?.[1] ?? "none";
    return majorMinor(version) === majorMinor(toolchain.xcode) || `found Xcode ${version}, pinned ${toolchain.xcode}`;
  },
);

check("Swift", true, `Select the Xcode that ships Swift ${toolchain.swift}.`, () => {
  const version = capture("xcrun", ["swift", "--version"]).output.match(/Swift version (\S+)/)?.[1] ?? "none";
  return majorMinor(version) === toolchain.swift || `found Swift ${version}, pinned ${toolchain.swift}`;
});

check("Simulator", true, "Install the iOS simulator runtime: xcodebuild -downloadPlatform iOS", () => {
  simulator();
  return true;
});

check("mise tools", true, "Trust and install the pinned tools: mise trust && mise install", () => {
  const listing = capture("mise", ["ls", "--current", "--json"]);
  if (!listing.ok) return listing.output.split("\n")[0];
  const installed = JSON.parse(listing.output);
  const missing = Object.entries(pinnedTools()).filter(
    ([tool, version]) => !installed[tool]?.some((entry) => entry.version === version && entry.installed),
  );
  return missing.length === 0 || `missing ${missing.map(([tool, version]) => `${tool}@${version}`).join(", ")}`;
});

check("Git hooks", false, "Install the Git hooks: mise run setup", () => {
  if (!existsSync(resolve(root, ".git"))) return "not a Git repository";
  const hooksPath = capture("git", ["config", "--get", "core.hooksPath"]).output.trim();
  return hooksPath === ".githooks" || "not installed";
});

const requiredOnly = process.argv.includes("--required");
const relevant = requiredOnly ? checks.filter((entry) => entry.required) : checks;
const ok = relevant.every((entry) => entry.ok);

if (process.argv.includes("--json")) {
  console.log(JSON.stringify({ ok, checks: relevant }, null, 2));
} else {
  for (const entry of relevant) {
    console.log(entry.ok ? `✓ ${entry.name}` : `✗ ${entry.name}: ${entry.detail}\n  fix: ${entry.fix}`);
  }
}
if (!ok) process.exitCode = 1;
