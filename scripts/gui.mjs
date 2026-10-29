import { existsSync, readdirSync, readFileSync, writeFileSync } from "node:fs";
import { resolve } from "node:path";
import { root } from "./lib.mjs";

const tokens = "Packages/UI/Sources/DesignSystem/Tokens";
const reference = "gui/theme.md";
const declaration = /^\s*public static let (\w+)(?::[^=]+)?\s*=\s*(.+)$/;

function depth(text) {
  return (text.match(/[([{]/g) ?? []).length - (text.match(/[)\]}]/g) ?? []).length;
}

function table(file) {
  const source = readFileSync(resolve(root, tokens, file), "utf8");
  const owner = source.match(/public enum (\w+)/)?.[1] ?? file.replace(/\.swift$/, "");
  const lines = source.split("\n");
  const rows = lines.flatMap((line, index) => {
    const match = line.match(declaration);
    if (!match) return [];
    let value = match[2];
    for (let next = index + 1; depth(value) > 0 && next < lines.length; next += 1) value += ` ${lines[next].trim()}`;
    return [`| \`${owner}.${match[1]}\` | \`${value.replace(/\(\s+/g, "(").replace(/\s+\)/g, ")").trim()}\` |`];
  });
  return [`## ${owner}`, "", "| Token | Value |", "| --- | --- |", ...rows].join("\n");
}

function render() {
  const files = readdirSync(resolve(root, tokens))
    .filter((name) => name.endsWith(".swift"))
    .sort();
  const intro = [
    "# Theme reference",
    "",
    `Generated from \`${tokens}/\` by \`mise run gui\`. Change a token there and regenerate. Don't edit this file: \`mise run check\` fails while it's stale. Spacing, radius, and stroke values are in points. The rules live in [GUI.md](../GUI.md).`,
  ].join("\n");
  return `${[intro, ...files.map(table)].join("\n\n")}\n`;
}

const expected = render();
const path = resolve(root, reference);
if (process.argv.includes("--check")) {
  const current = existsSync(path) ? readFileSync(path, "utf8") : "";
  if (current !== expected) {
    console.log(`${reference} is stale. Run mise run gui and commit the result.`);
    process.exitCode = 1;
  } else {
    console.log(`gui: ${reference} matches the tokens`);
  }
} else {
  writeFileSync(path, expected);
  console.log(`Wrote ${reference}`);
}
