import { mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { parseArgs } from "node:util";
import { capture, derivedData, identity, root, run, simulator, workspace } from "./lib.mjs";

const { values } = parseArgs({
  options: {
    screenshot: { type: "string" },
    wait: { type: "string", default: "3" },
    open: { type: "boolean", default: false },
  },
});

const { name, bundleID } = identity();
const udid = simulator();

run("tuist", ["generate", "--no-open"]);
const build = capture("xcodebuild", [
  "build",
  "-workspace",
  workspace(),
  "-scheme",
  name,
  "-destination",
  `id=${udid}`,
  "-derivedDataPath",
  derivedData,
  "-quiet",
]);
if (!build.ok) {
  console.error(build.output.replaceAll(`${root}/`, ""));
  process.exit(1);
}

capture("xcrun", ["simctl", "boot", udid]);
run("xcrun", ["simctl", "bootstatus", udid, "-b"]);
if (values.open) run("open", ["-a", resolve(run("xcode-select", ["-p"]), "../Applications/DeviceHub.app")]);
run("xcrun", ["simctl", "install", udid, resolve(derivedData, "Build/Products/Debug-iphonesimulator", `${name}.app`)]);
run("xcrun", ["simctl", "launch", "--terminate-running-process", udid, bundleID]);
console.log(`Launched ${name} on ${udid}`);

if (values.screenshot) {
  const path = resolve(root, values.screenshot);
  mkdirSync(dirname(path), { recursive: true });
  await new Promise((settle) => setTimeout(settle, Number(values.wait) * 1_000));
  run("xcrun", ["simctl", "io", udid, "screenshot", path]);
  console.log(`Screenshot: ${path}`);
}
