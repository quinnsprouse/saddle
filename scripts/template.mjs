import assert from "node:assert/strict";
import { cpSync, existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join, resolve } from "node:path";
import { capture, root, run } from "./lib.mjs";

const copy = mkdtempSync(join(tmpdir(), "saddle-template-"));
const env = { ...process.env, MISE_TRUSTED_CONFIG_PATHS: copy };
for (const key of ["GIT_DIR", "GIT_INDEX_FILE", "GIT_WORK_TREE", "CLAUDE_PROJECT_DIR"]) delete env[key];

function inCopy(command, args) {
  const result = capture(command, args, { cwd: copy, env: { ...env, PATH: process.env.PATH } });
  assert.ok(result.ok, `${command} ${args.join(" ")} failed in ${copy}:\n${result.output.slice(-4_000)}`);
  return result.output;
}

function step(name, body) {
  process.stdout.write(`▸ ${name}\n`);
  body();
}

try {
  step("copy the staged files into a fresh directory", () => {
    run("git", ["checkout-index", "--all", "--prefix", `${copy}/`]);
    assert.ok(existsSync(join(copy, "Tools/Package.resolved")), "Stage the template, including Tools/Package.resolved.");
    assert.ok(!existsSync(join(copy, ".git")));
  });
  step("set up Git hooks and the workspace", () => {
    inCopy("git", ["init", "--quiet", "--initial-branch=main"]);
    inCopy("node", ["scripts/setup.mjs"]);
  });
  step("the commit-msg hook enforces Conventional Commits", () => {
    const message = join(copy, ".scratch-commit-message");
    writeFileSync(message, "updated things\n");
    assert.ok(!capture("sh", [".githooks/commit-msg", message], { cwd: copy, env }).ok, "accepted a bad message");
    writeFileSync(message, "feat: start the app\n");
    inCopy("sh", [".githooks/commit-msg", message]);
    rmSync(message);
  });
  step("the fresh copy passes check", () => {
    inCopy("node", ["scripts/verify.mjs", "fast"]);
  });
  step("a renamed app passes check", () => {
    const identity = readFileSync(join(copy, "Tuist/ProjectDescriptionHelpers/Identity.swift"), "utf8");
    const original = identity.match(/static let name = "([^"]+)"/)?.[1];
    const renamed = original === "Trailhead" ? "Wayfinder" : "Trailhead";
    inCopy("node", ["scripts/rename.mjs", renamed, `dev.example.${renamed.toLowerCase()}`]);
    inCopy("node", ["scripts/verify.mjs", "fast"]);
    assert.ok(existsSync(join(copy, `${renamed}.xcworkspace`)), "the renamed workspace was not generated");
    assert.ok(!existsSync(join(copy, `${original}.xcworkspace`)), "the old workspace survived the rename");
  });
  rmSync(copy, { recursive: true, force: true });
  console.log(`template: a fresh copy of the staged files sets up, passes check, and renames cleanly (${root})`);
} catch (error) {
  const logs = join(copy, ".scratch/logs");
  if (existsSync(logs)) cpSync(logs, resolve(root, ".scratch/logs/template"), { recursive: true });
  console.error(`${error.message}\nTemplate evidence kept at ${copy}; its logs are in .scratch/logs/template`);
  process.exitCode = 1;
}
