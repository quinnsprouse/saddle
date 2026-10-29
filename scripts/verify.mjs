import { rmSync } from "node:fs";
import { relative, resolve } from "node:path";
import { capture, derivedData, identity, root, simulator, swiftFiles, workspace, writeLog } from "./lib.mjs";

const policyBinary = ".build/spm/tools/debug/policy";
const diagnosticLimit = 40;

const sanitizedData = resolve(root, ".build/DerivedData-tsan");
const analyzedData = resolve(root, ".build/DerivedData-analyze");

function xcodebuild(action, ...extra) {
  return xcodebuildIn(derivedData, action, ...extra);
}

function xcodebuildIn(dataPath, action, ...extra) {
  const scheme = identity().name;
  const args = [action, "-workspace", workspace(), "-scheme", scheme, "-derivedDataPath", dataPath, "-quiet"];
  return capture("xcodebuild", [...args, ...extra]);
}

function analyze() {
  const scheme = identity().name;
  const build = capture("xcodebuild", [
    "clean",
    "build-for-testing",
    "-workspace",
    workspace(),
    "-scheme",
    scheme,
    "-destination",
    "generic/platform=iOS Simulator",
    "-derivedDataPath",
    analyzedData,
  ]);
  if (!build.ok) return build;
  const log = writeLog("analyze-build", build.output);
  return capture("swiftlint", ["analyze", "--strict", "--quiet", "--compiler-log-path", log]);
}

function sequence(...commands) {
  let output = "";
  for (const command of commands) {
    const result = command();
    output += result.output;
    if (!result.ok) return { ok: false, output };
  }
  return { ok: true, output };
}

const fast = [
  { name: "toolchain", run: () => capture("node", ["scripts/doctor.mjs", "--required"]) },
  { name: "contract", run: () => capture("node", ["scripts/contract.mjs"]) },
  { name: "hook tests", run: () => capture("node", ["scripts/test-hooks.mjs"]) },
  { name: "comments", run: () => capture("node", ["scripts/comments.mjs"]) },
  { name: "theme reference", run: () => capture("node", ["scripts/gui.mjs", "--check"]) },
  { name: "format", run: () => capture("xcrun", ["swift-format", "lint", "--strict", "--parallel", ...swiftFiles()]) },
  { name: "lint", run: () => capture("swiftlint", ["lint", "--strict", "--quiet"]) },
  {
    name: "policy",
    run: () =>
      sequence(
        () => capture("swift", ["build", "--package-path", "Tools", "--scratch-path", ".build/spm/tools"]),
        () => capture(policyBinary, ["--config", "policy.json", ...swiftFiles()]),
      ),
  },
  {
    name: "policy tests",
    run: () => capture("swift", ["test", "--package-path", "Tools", "--scratch-path", ".build/spm/tools"]),
  },
  {
    name: "import check",
    run: () =>
      capture("swift", [
        "build",
        "--package-path",
        "Packages/Core",
        "--scratch-path",
        ".build/spm/core",
        "--explicit-target-dependency-import-check",
        "error",
      ]),
  },
  { name: "generate", run: () => capture("tuist", ["generate", "--no-open"]) },
  {
    name: "build",
    needs: "generate",
    run: () => xcodebuild("build-for-testing", "-destination", "generic/platform=iOS Simulator"),
  },
];

const push = [
  {
    name: "release build",
    needs: "generate",
    run: () => xcodebuild("build", "-configuration", "Release", "-destination", "generic/platform=iOS Simulator"),
  },
  { name: "analyze", needs: "generate", run: analyze },
  {
    name: "sanitized build",
    needs: "generate",
    run: () =>
      xcodebuildIn(
        sanitizedData,
        "build-for-testing",
        "-destination",
        `id=${simulator()}`,
        "-enableThreadSanitizer",
        "YES",
        "ENABLE_THREAD_SANITIZER=YES",
        "COMPILER_INDEX_STORE_ENABLE=NO",
      ),
  },
  {
    name: "journeys",
    needs: "sanitized build",
    run: () => {
      const bundle = resolve(root, ".scratch/results/ui.xcresult");
      rmSync(bundle, { recursive: true, force: true });
      const device = simulator();
      capture("xcrun", ["simctl", "boot", device]);
      const booted = capture("xcrun", ["simctl", "bootstatus", device, "-b"]);
      if (!booted.ok) return booted;
      const result = xcodebuildIn(
        sanitizedData,
        "test-without-building",
        "-destination",
        `id=${device}`,
        "-enableThreadSanitizer",
        "YES",
        "-only-testing:UITests",
        "-parallel-testing-enabled",
        "NO",
        "-collect-test-diagnostics",
        "never",
        "-resultBundlePath",
        bundle,
      );
      return { ...result, output: `${result.output}\nresult bundle: ${relative(root, bundle)}\n` };
    },
  },
  {
    name: "dead code",
    needs: "build",
    run: () =>
      capture("periphery", [
        "scan",
        "--project",
        workspace(),
        "--schemes",
        identity().name,
        "--index-store-path",
        resolve(derivedData, "Index.noindex/DataStore"),
        "--retain-swift-ui-previews",
        "--retain-files",
        "Packages/UI/Sources/DesignSystem/Tokens/*.swift",
        "--relative-results",
        "--strict",
        "--disable-update-check",
        "--quiet",
      ]),
  },
  { name: "dependencies", needs: "generate", run: () => capture("tuist", ["inspect", "dependencies"]) },
];

const ci = [{ name: "template", run: () => capture("node", ["scripts/template.mjs"]) }];

const everything = [...fast, ...push, ...ci];
const lane = (names) => everything.filter((step) => names.includes(step.name));
const builds = lane(["generate", "build", "release build", "analyze", "dead code", "dependencies"]);
const journeys = lane(["generate", "sanitized build", "journeys"]);
const laned = new Set([...builds, ...journeys, ...ci].map((step) => step.name));
const tiers = {
  fast,
  push: [...fast, ...push],
  ci: everything,
  "ci-static": everything.filter((step) => !laned.has(step.name)),
  "ci-build": builds,
  "ci-journeys": journeys,
  "ci-template": ci,
};

function diagnostics(output) {
  const text = output.replaceAll(`${root}/`, "");
  const lines = text.split("\n");
  const flagged = lines.filter((line) => /:\d+(:\d+)?: (error|warning):|✘|^\s*error:|^Error:|^✗|fix:/.test(line));
  const chosen = flagged.length > 0 ? [...new Set(flagged)] : lines.filter(Boolean).slice(-diagnosticLimit);
  const extra = chosen.length > diagnosticLimit ? `\n… ${chosen.length - diagnosticLimit} more` : "";
  return chosen.slice(0, diagnosticLimit).join("\n") + extra;
}

function attempt(step) {
  try {
    return step.run();
  } catch (error) {
    return { ok: false, output: `${step.name} could not run: ${error.message}` };
  }
}

const tier = process.argv[2];
const steps = tiers[tier];
if (steps === undefined) {
  console.error(`usage: node scripts/verify.mjs <${Object.keys(tiers).join("|")}>`);
  process.exit(64);
}

const started = Date.now();
const failed = new Set();
for (const step of steps) {
  if (step.needs && failed.has(step.needs)) {
    console.log(`- ${step.name} skipped because ${step.needs} failed`);
    failed.add(step.name);
    continue;
  }
  const stepStarted = Date.now();
  const result = attempt(step);
  const seconds = ((Date.now() - stepStarted) / 1000).toFixed(1);
  const log = writeLog(step.name.replaceAll(" ", "-"), result.output);
  if (result.ok) {
    console.log(`✓ ${step.name} (${seconds}s)`);
  } else {
    failed.add(step.name);
    console.log(`✗ ${step.name} (${seconds}s)\n${diagnostics(result.output)}\n  log: ${relative(root, log)}`);
  }
}

const total = ((Date.now() - started) / 1000).toFixed(1);
if (failed.size > 0) {
  console.log(`\n${tier} failed in ${total}s: ${[...failed].join(", ")}`);
  process.exitCode = 1;
} else {
  console.log(`\n${tier} passed in ${total}s`);
}
