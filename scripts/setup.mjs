import { existsSync } from "node:fs";
import { resolve } from "node:path";
import { root, run } from "./lib.mjs";

if (existsSync(resolve(root, ".git"))) {
  run("git", ["config", "--local", "core.hooksPath", ".githooks"]);
  console.log("Git hooks installed from .githooks");
} else {
  console.log("Git hooks skipped. Run git init --initial-branch=main, then mise run setup.");
}
run("tuist", ["generate", "--no-open"]);
console.log("Xcode workspace generated. Open it with: xed .");
