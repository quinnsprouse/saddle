import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { relative, resolve } from "node:path";
import { parseArgs } from "node:util";
import { capture, derivedData, root, run, simulator, workspace } from "./lib.mjs";

const schema = 2;
const directory = resolve(root, ".scratch/perf");
const { values } = parseArgs({
  options: {
    device: { type: "string" },
    team: { type: "string" },
    save: { type: "string" },
    compare: { type: "string" },
  },
});
const { tolerances } = JSON.parse(readFileSync(resolve(root, "performance.json"), "utf8"));
const worseWhen = { "prefers smaller": 1, "prefers larger": -1 };

if ([values.save, values.compare].includes("latest")) {
  console.error("latest is the current report. Save and compare baselines under another name.");
  process.exit(64);
}

function loadBaseline(name) {
  if (name === undefined) return undefined;
  const path = resolve(directory, `${name}.json`);
  if (!existsSync(path)) {
    console.error(`No baseline ${relative(root, path)}. Save one first: mise run perf -- --save ${name}`);
    process.exit(2);
  }
  return JSON.parse(readFileSync(path, "utf8"));
}

const baseline = loadBaseline(values.compare);

function median(samples) {
  const sorted = samples.toSorted((left, right) => left - right);
  const middle = Math.floor(sorted.length / 2);
  return sorted.length % 2 === 0 ? (sorted[middle - 1] + sorted[middle]) / 2 : sorted[middle];
}

function results(bundle) {
  return (kind) => JSON.parse(run("xcrun", ["xcresulttool", "get", "test-results", kind, "--path", bundle, "--compact"]));
}

function measure() {
  mkdirSync(directory, { recursive: true });
  const bundle = resolve(directory, "latest.xcresult");
  rmSync(bundle, { recursive: true, force: true });
  run("tuist", ["generate", "--no-open"]);
  const signing = values.device ? ["-allowProvisioningUpdates", `DEVELOPMENT_TEAM=${values.team ?? ""}`] : [];
  const destination = `id=${values.device ?? simulator()}`;
  const test = capture("xcodebuild", [
    "test",
    "-workspace",
    workspace(),
    "-scheme",
    "Performance",
    "-destination",
    destination,
    "-derivedDataPath",
    derivedData,
    "-resultBundlePath",
    bundle,
    "-quiet",
    ...signing,
  ]);
  if (!test.ok) {
    console.error(test.output.replaceAll(`${root}/`, "").split("\n").slice(-40).join("\n"));
    process.exit(1);
  }
  const read = results(bundle);
  const device = read("summary").devicesAndConfigurations[0].device;
  const metrics = {};
  for (const entry of read("metrics")) {
    if (entry.testRuns.length !== 1) {
      throw new Error(`${entry.testIdentifier} has ${entry.testRuns.length} runs. Measure one destination at a time.`);
    }
    for (const metric of entry.testRuns[0].metrics) {
      metrics[`${entry.testIdentifier.split("/")[0]}: ${metric.displayName}`] = {
        unit: metric.unitOfMeasurement,
        polarity: metric.polarity,
        samples: metric.measurements,
        median: median(metric.measurements),
      };
    }
  }
  const commit = capture("git", ["rev-parse", "--short", "HEAD"]);
  return {
    schema,
    measuredAt: new Date().toISOString(),
    commit: commit.ok ? commit.output.trim() : "none",
    dirty: run("git", ["status", "--porcelain"]) !== "",
    environment: {
      mac: run("sysctl", ["-n", "hw.model"]),
      macOS: run("sw_vers", ["-productVersion"]),
      xcode: run("xcodebuild", ["-version"]).replaceAll("\n", " "),
      destination: [
        device.platform,
        device.modelName,
        `${device.osVersion} (${device.osBuildNumber})`,
        ...(device.platform === "iOS Simulator" ? [] : [device.deviceId]),
      ].join(" "),
    },
    metrics,
  };
}

function compare(current, baseline) {
  const mismatched = Object.keys(current.environment).filter(
    (key) => current.environment[key] !== baseline.environment[key],
  );
  if (current.schema !== baseline.schema) mismatched.push("schema");
  if (mismatched.length > 0) {
    console.error(`Refusing to compare: ${mismatched.join(", ")} differ from the baseline. Measure both on one setup.`);
    process.exit(2);
  }
  const regressions = [];
  for (const [name, before] of Object.entries(baseline.metrics)) {
    const after = current.metrics[name];
    if (after === undefined) {
      regressions.push(`${name}: missing from this run`);
      continue;
    }
    const allowed = Math.max(tolerances.relative * before.median, tolerances.floors[before.unit] ?? 0);
    const direction = worseWhen[before.polarity];
    const worsening = direction === undefined ? 0 : (after.median - before.median) * direction;
    const percent = before.median === 0 ? 0 : ((after.median - before.median) / before.median) * 100;
    const verdict = direction === undefined ? "info" : worsening > allowed ? "regressed" : "ok";
    console.log(`${verdict.padEnd(9)} ${name}: ${before.median.toFixed(4)} → ${after.median.toFixed(4)} ${after.unit} (${percent >= 0 ? "+" : ""}${percent.toFixed(1)}%)`);
    if (verdict === "regressed") regressions.push(name);
  }
  return regressions;
}

const report = measure();
writeFileSync(resolve(directory, "latest.json"), `${JSON.stringify(report, null, 2)}\n`);
for (const [name, metric] of Object.entries(report.metrics)) {
  console.log(`${name}: median ${metric.median.toFixed(4)} ${metric.unit} over ${metric.samples.length} runs`);
}
console.log(`${report.environment.destination}, ${report.environment.xcode}. Report: ${relative(root, directory)}/latest.json`);

if (values.save) {
  writeFileSync(resolve(directory, `${values.save}.json`), `${JSON.stringify(report, null, 2)}\n`);
  console.log(`Saved baseline ${relative(root, directory)}/${values.save}.json`);
}
if (baseline) {
  const regressions = compare(report, baseline);
  if (regressions.length > 0) {
    console.error(`${regressions.length} regressed beyond tolerance. Repeat the run, then profile before you accept it.`);
    process.exitCode = 1;
  }
}
