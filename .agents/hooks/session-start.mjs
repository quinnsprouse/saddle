import { capture } from "../../scripts/lib.mjs";

const report = capture("node", ["scripts/doctor.mjs", "--json"], { timeout: 20_000 });
try {
  const problems = JSON.parse(report.output).checks.filter((check) => !check.ok);
  if (problems.length === 0) {
    console.log("saddle doctor: workspace healthy");
  } else {
    console.log("saddle doctor found problems. Fix these before you edit:");
    for (const problem of problems) console.log(`  ✗ ${problem.name}: ${problem.detail}\n    fix: ${problem.fix}`);
  }
} catch {
  console.log("saddle doctor could not run. Install the toolchain: mise trust && mise install");
}
