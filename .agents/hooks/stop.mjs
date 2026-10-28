import { createHash } from "node:crypto";
import { existsSync, readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { capture, root, run } from "../../scripts/lib.mjs";

const timeoutMs = 270_000;

function respond(output) {
  console.log(JSON.stringify(output));
  process.exit(0);
}

const input = JSON.parse(readFileSync(0, "utf8"));
if (!existsSync(resolve(root, ".git")) || run("git", ["status", "--porcelain=v1"]) === "") process.exit(0);

const hash = createHash("sha256")
  .update(run("git", ["diff", "--binary"]))
  .update(run("git", ["diff", "--cached", "--binary"]));
for (const file of run("git", ["ls-files", "--others", "--exclude-standard", "-z"]).split("\0").filter(Boolean)) {
  const path = resolve(root, file);
  hash.update(file).update(existsSync(path) ? readFileSync(path) : "");
}
const fingerprint = hash.digest("hex");
const cache = resolve(root, run("git", ["rev-parse", "--git-path", "saddle-stop.json"]));
const previous = existsSync(cache) ? JSON.parse(readFileSync(cache, "utf8")) : {};

if (previous.fingerprint === fingerprint && previous.ok) process.exit(0);
if (previous.fingerprint === fingerprint && input.stop_hook_active) {
  respond({ systemMessage: "mise run check still fails on these changes. Run it to see the failures." });
}

const result = capture("node", ["scripts/verify.mjs", "fast"], { timeout: timeoutMs });
if (result.status === null) {
  writeFileSync(cache, JSON.stringify({ fingerprint, ok: false }));
  respond({
    decision: "block",
    reason:
      "mise run check did not finish within 270 seconds, usually because of a cold build. Run it to completion " +
      "and fix any failure.",
  });
}
writeFileSync(cache, JSON.stringify({ fingerprint, ok: result.ok }));
if (!result.ok) {
  respond({ decision: "block", reason: `Fix the checks before you finish:\n${result.output.slice(-5_000)}` });
}
