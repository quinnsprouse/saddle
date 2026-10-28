import { readFileSync, rmSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { identity, root } from "./lib.mjs";

const [name, bundleID] = process.argv.slice(2);
if (!/^[A-Z][A-Za-z0-9]*$/.test(name ?? "") || !/^[A-Za-z][A-Za-z0-9-]*(?:\.[A-Za-z0-9-]+)+$/.test(bundleID ?? "")) {
  console.error("usage: mise run rename -- <AppName> <bundle.identifier>, for example: mise run rename -- Trail dev.example.trail");
  process.exit(64);
}

const previous = identity().name;
const path = resolve(root, "Tuist/ProjectDescriptionHelpers/Identity.swift");
const source = readFileSync(path, "utf8")
  .replace(/static let name = "[^"]+"/, `static let name = "${name}"`)
  .replace(/static let bundleID = "[^"]+"/, `static let bundleID = "${bundleID}"`);
writeFileSync(path, source);
for (const generated of [`${previous}.xcworkspace`, `${previous}.xcodeproj`, "Derived"]) {
  rmSync(resolve(root, generated), { recursive: true, force: true });
}
console.log(`Renamed ${previous} to ${name} (${bundleID}). Run mise run generate to rebuild the workspace.`);
