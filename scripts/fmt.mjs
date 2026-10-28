import { run, swiftFiles } from "./lib.mjs";

run("xcrun", ["swift-format", "format", "--in-place", "--parallel", ...swiftFiles()]);
run("swiftlint", ["lint", "--fix", "--quiet"]);
console.log("Formatted with swift-format and applied SwiftLint autocorrections.");
