import { existsSync, readdirSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { identity, root, run, toolchain } from "./lib.mjs";

const upcomingFeatures = [
  "ExistentialAny",
  "InternalImportsByDefault",
  "MemberImportVisibility",
  "NonisolatedNonsendingByDefault",
  "InferIsolatedConformances",
];
const mainActorPackages = new Set(["Packages/UI"]);
const xcodeSettings = {
  SWIFT_VERSION: "6.0",
  SWIFT_STRICT_CONCURRENCY: "complete",
  SWIFT_TREAT_WARNINGS_AS_ERRORS: "YES",
  GCC_TREAT_WARNINGS_AS_ERRORS: "YES",
  SWIFT_DEFAULT_ACTOR_ISOLATION: "MainActor",
  SWIFT_APPROACHABLE_CONCURRENCY: "YES",
  SWIFT_STRICT_MEMORY_SAFETY: "YES",
  SWIFT_UPCOMING_FEATURE_EXISTENTIAL_ANY: "YES",
  SWIFT_UPCOMING_FEATURE_INTERNAL_IMPORTS_BY_DEFAULT: "YES",
  SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY: "YES",
};
const problems = [];

function packages() {
  const local = readdirSync(resolve(root, "Packages"), { withFileTypes: true })
    .filter((entry) => entry.isDirectory() && existsSync(resolve(root, "Packages", entry.name, "Package.swift")))
    .map((entry) => `Packages/${entry.name}`);
  return [...local, "Tools"];
}

function settingKinds(target) {
  return target.settings
    .filter((setting) => setting.tool === "swift" && setting.condition === undefined)
    .map((setting) => setting.kind);
}

function checkTarget(path, target) {
  const kinds = settingKinds(target);
  const has = (name, value) => kinds.some((kind) => kind[name] && (value === undefined || kind[name]._0 === value));
  const where = `${path}/Package.swift target ${target.name}`;
  if (!has("treatAllWarnings", "error")) problems.push(`${where}: add .treatAllWarnings(as: .error).`);
  if (!has("strictMemorySafety")) problems.push(`${where}: add .strictMemorySafety().`);
  for (const feature of upcomingFeatures.filter((name) => !has("enableUpcomingFeature", name))) {
    problems.push(`${where}: add .enableUpcomingFeature("${feature}").`);
  }
  if (mainActorPackages.has(path) && target.type !== "test" && !has("defaultIsolation", "MainActor")) {
    problems.push(`${where}: UI modules need .defaultIsolation(MainActor.self).`);
  }
}

function checkPackage(path) {
  const manifest = JSON.parse(run("swift", ["package", "dump-package", "--package-path", path]));
  for (const target of manifest.targets) checkTarget(path, target);
  const ios = manifest.platforms.find((platform) => platform.platformName === "ios");
  if (path !== "Tools" && ios?.version !== toolchain.ios) {
    problems.push(`${path}/Package.swift: set .iOS("${toolchain.ios}") to match toolchain.json.`);
  }
  for (const dependency of manifest.dependencies.flatMap((entry) => entry.sourceControl ?? [])) {
    if (!dependency.requirement.exact) {
      problems.push(`${path}/Package.swift: pin ${dependency.identity} with exact: "<version>".`);
    }
  }
}

function checkXcodeSettings() {
  const helper = readFileSync(resolve(root, "Tuist/ProjectDescriptionHelpers/BuildSettings.swift"), "utf8")
    .replace(/\/\*[\s\S]*?\*\//g, "")
    .replace(/\/\/.*$/gm, "");
  for (const [key, value] of Object.entries(xcodeSettings)) {
    if (!helper.includes(`"${key}": "${value}"`)) {
      problems.push(`Tuist/ProjectDescriptionHelpers/BuildSettings.swift: strict must set "${key}": "${value}".`);
    }
  }
  const project = readFileSync(resolve(root, "Project.swift"), "utf8");
  for (const key of Object.keys(xcodeSettings).filter((name) => project.includes(name))) {
    problems.push(`Project.swift: move ${key} into BuildSettings.swift; targets must not override it.`);
  }
  if (identity().deploymentTarget !== toolchain.ios) {
    problems.push(`Tuist/ProjectDescriptionHelpers/Identity.swift: set deploymentTarget to "${toolchain.ios}".`);
  }
}

for (const path of packages()) checkPackage(path);
checkXcodeSettings();

if (problems.length > 0) {
  console.log(problems.join("\n"));
  process.exitCode = 1;
} else {
  console.log("contract: compiler settings, platforms, and pins hold");
}
