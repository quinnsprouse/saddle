import { spawnSync } from "node:child_process";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";
import { dirname, resolve } from "node:path";

export const root = resolve(import.meta.dirname, "..");
export const derivedData = resolve(root, ".build/DerivedData");
export const toolchain = JSON.parse(readFileSync(resolve(root, "toolchain.json"), "utf8"));

export function identity() {
  const source = readFileSync(resolve(root, "Tuist/ProjectDescriptionHelpers/Identity.swift"), "utf8");
  const value = (key) => source.match(new RegExp(`static let ${key} = "([^"]+)"`))?.[1];
  return { name: value("name"), bundleID: value("bundleID"), deploymentTarget: value("deploymentTarget") };
}

export function workspace() {
  return `${identity().name}.xcworkspace`;
}

export function pinnedTools() {
  const manifest = readFileSync(resolve(root, "mise.toml"), "utf8");
  const section = manifest.match(/^\[tools\]\n([\s\S]*?)(?:\n\[|$)/m)?.[1] ?? "";
  return Object.fromEntries([...section.matchAll(/^([\w-]+) = "([^"]+)"$/gm)].map((match) => [match[1], match[2]]));
}

let environment;
export function toolEnv() {
  if (environment === undefined) {
    const result = spawnSync("mise", ["env", "--json"], { cwd: root, encoding: "utf8" });
    const tools = result.status === 0 ? JSON.parse(result.stdout) : {};
    environment = { ...process.env, ...tools, NO_COLOR: "1", TUIST_DISABLE_ANALYTICS: "1" };
    delete environment.CLAUDE_PROJECT_DIR;
  }
  return environment;
}

export function capture(command, args, options = {}) {
  const result = spawnSync(command, args, {
    cwd: root,
    encoding: "utf8",
    env: toolEnv(),
    maxBuffer: 64 * 1024 * 1024,
    ...options,
  });
  const failure = result.error ? `\n${result.error.message}` : "";
  const output = `${result.stdout ?? ""}${result.stderr ?? ""}${failure}`;
  return { ok: result.status === 0 && !result.error, status: result.status, output };
}

export function run(command, args, options = {}) {
  const result = capture(command, args, options);
  if (!result.ok) throw new Error(`${command} ${args.join(" ")} failed:\n${result.output}`);
  return result.output.trim();
}

export function swiftFiles() {
  const listed = run("git", ["ls-files", "--cached", "--others", "--exclude-standard", "-z", "--", "*.swift"]);
  return [...new Set(listed.split("\0").filter(Boolean))].filter((path) => existsSync(resolve(root, path)));
}

export function simulator() {
  const runtime = `iOS-${run("xcrun", ["--sdk", "iphonesimulator", "--show-sdk-version"]).replaceAll(".", "-")}`;
  const devices = JSON.parse(run("xcrun", ["simctl", "list", "devices", "available", "-j"])).devices;
  const matches = Object.entries(devices)
    .filter(([key]) => key.endsWith(runtime))
    .flatMap(([, list]) => list)
    .filter((device) => device.name === toolchain.simulator);
  if (matches.length === 0) {
    throw new Error(
      `No available "${toolchain.simulator}" simulator on ${runtime}. Run \`xcodebuild -downloadPlatform iOS\`, ` +
        `or create one with \`xcrun simctl create "${toolchain.simulator}" "${toolchain.simulator}" ` +
        `com.apple.CoreSimulator.SimRuntime.${runtime}\`.`,
    );
  }
  return matches[0].udid;
}

export function writeLog(name, text) {
  const path = resolve(root, ".scratch/logs", `${name}.log`);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text);
  return path;
}
