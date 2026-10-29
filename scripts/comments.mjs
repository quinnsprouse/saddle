import { existsSync, readFileSync } from "node:fs";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import { root, run } from "./lib.mjs";

const regexAfterPunctuation = new Set([..."(,=:[!&|?{};+-*%<>~^"]);
const regexAfterWords = new Set(["return", "typeof", "case", "do", "else", "in", "of", "new", "delete", "void", "throw"]);
const controlWords = new Set(["if", "while", "for", "with"]);
const pinnedActionVersion = /^\s*-?\s*uses:\s*\S+@[0-9a-f]{40}\s+#\s*v[\w.-]+\s*$/;
const quotedText = /"(?:[^"\\]|\\.)*"|'[^']*'/g;

function skipQuoted(source, start, quote) {
  let index = start + 1;
  while (index < source.length && source[index] !== quote) index += source[index] === "\\" ? 2 : 1;
  return index + 1;
}

function skipRegex(source, start) {
  let index = start + 1;
  let inClass = false;
  while (index < source.length && source[index] !== "\n") {
    const character = source[index];
    if (character === "\\") {
      index += 2;
      continue;
    }
    if (character === "/" && !inClass) break;
    if (character === "[") inClass = true;
    if (character === "]") inClass = false;
    index += 1;
  }
  index += 1;
  while (/[a-z]/i.test(source[index] ?? "")) index += 1;
  return index;
}

function scanTemplate(source, start) {
  let index = start;
  while (index < source.length) {
    if (source[index] === "\\") index += 2;
    else if (source[index] === "`") return { index: index + 1, interpolation: false };
    else if (source[index] === "$" && source[index + 1] === "{") return { index: index + 2, interpolation: true };
    else index += 1;
  }
  return { index, interpolation: false };
}

function commentEnd(source, index) {
  const block = source[index + 1] === "*";
  const end = block ? source.indexOf("*/", index + 2) : source.indexOf("\n", index);
  if (end === -1) return source.length;
  return block ? end + 2 : end;
}

function lineOf(source, index) {
  return source.slice(0, index).split("\n").length;
}

function startsRegex(previous) {
  return (
    previous === "" ||
    previous === "control)" ||
    regexAfterPunctuation.has(previous) ||
    regexAfterWords.has(previous)
  );
}

export function javaScriptCommentLines(source) {
  const lines = [];
  const templates = [];
  const parentheses = [];
  let depth = 0;
  let previous = "";
  let index = 0;
  while (index < source.length) {
    const character = source[index];
    const next = source[index + 1];
    if (/\s/.test(character)) {
      index += 1;
    } else if (character === "/" && (next === "/" || next === "*")) {
      lines.push(lineOf(source, index));
      index = commentEnd(source, index);
    } else if (character === "'" || character === '"') {
      index = skipQuoted(source, index, character);
      previous = "value";
    } else if (character === "`" || (character === "}" && templates.at(-1) === depth)) {
      if (character === "}") templates.pop();
      const scanned = scanTemplate(source, index + 1);
      if (scanned.interpolation) templates.push(depth);
      index = scanned.index;
      previous = scanned.interpolation ? "{" : "value";
    } else if (character === "/" && startsRegex(previous)) {
      index = skipRegex(source, index);
      previous = "value";
    } else if ((character === "+" || character === "-") && next === character) {
      index += 2;
      previous = startsRegex(previous) ? character : "value";
    } else if (/[\w$]/.test(character)) {
      const word = source.slice(index).match(/^[\w$]+/)[0];
      index += word.length;
      previous = previous === "." ? "member" : word;
    } else {
      if (character === "(") parentheses.push(controlWords.has(previous));
      if (character === "{") depth += 1;
      if (character === "}") depth -= 1;
      previous = character === ")" && parentheses.pop() ? "control)" : character;
      index += 1;
    }
  }
  return lines;
}

export function hashCommentLines(source) {
  return source
    .split("\n")
    .map((text, offset) => ({ text, line: offset + 1 }))
    .filter(({ text, line }) => !(line === 1 && text.startsWith("#!")) && !pinnedActionVersion.test(text))
    .filter(({ text }) => /(?:^|\s)#/.test(text.replace(quotedText, "")))
    .map(({ line }) => line);
}

function checkedFiles() {
  return run("git", ["ls-files", "--cached", "--others", "--exclude-standard", "-z"])
    .split("\0")
    .filter(Boolean)
    .filter((path) => !/^\.(?:agents|claude)\/skills\//.test(path))
    .filter((path) => /\.(?:mjs|js|sh|ya?ml|toml)$/.test(path) || path.startsWith(".githooks/"))
    .filter((path) => existsSync(resolve(root, path)));
}

function main() {
  const problems = [];
  for (const path of checkedFiles()) {
    const source = readFileSync(resolve(root, path), "utf8");
    const lines = /\.m?js$/.test(path) ? javaScriptCommentLines(source) : hashCommentLines(source);
    for (const line of lines) problems.push(`${path}:${line}: error: Comments are banned. Say it in code instead. [comment]`);
  }
  console.log(problems.length > 0 ? problems.join("\n") : "comments: no comments outside Swift either");
  if (problems.length > 0) process.exitCode = 1;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) main();
