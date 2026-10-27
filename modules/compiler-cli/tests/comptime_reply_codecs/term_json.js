// Decisions 1035 (4), 1058 (1) — an Erlang term as `comptime_reply_codecs.sh`
// reads it from a snapshot's `;; ArgN = …` listing, written as the crossing's
// JSON (`compiler.bp` § what crosses in): a map an object of the same keys,
// a binary a string, `undefined` null, `true` / `false` booleans, any other
// atom a string, a tuple an array. Each line of stdin is one term; each line of
// stdout its JSON, every object's keys sorted, compact. With `--json` each line
// is already JSON (the hand-written inputs), only sorted.
"use strict";
const lines = require("fs").readFileSync(0, "utf8").split("\n").filter((l) => l.length > 0);

function parse(text) {
  let i = 0;
  const space = () => { while (i < text.length && /\s/.test(text[i])) i++; };
  const fail = (what) => { throw new Error(`${what} at ${i}: ${text.slice(i, i + 30)}`); };
  const quoted = (q) => {
    let out = "";
    i++;
    while (text[i] !== q) {
      if (i >= text.length) fail("an unterminated text");
      if (text[i] === "\\") {
        const e = text[i + 1];
        const map = { n: "\n", r: "\r", t: "\t", v: "\v", b: "\b", f: "\f", e: "\x1b", d: "\x7f", s: " " };
        out += e in map ? map[e] : e;
        i += 2;
      } else out += text[i++];
    }
    i++;
    return out;
  };
  const value = () => {
    space();
    const c = text[i];
    if (text.startsWith("#{", i)) {
      i += 2;
      const obj = {};
      space();
      if (text[i] === "}") { i++; return obj; }
      for (;;) {
        space();
        const key = text[i] === "'" ? quoted("'") : atomName();
        space();
        if (!text.startsWith("=>", i)) fail("no =>");
        i += 2;
        obj[key] = value();
        space();
        if (text[i] === ",") { i++; continue; }
        if (text[i] === "}") { i++; return obj; }
        fail("a malformed map");
      }
    }
    if (c === "[" || c === "{") {
      const close = c === "[" ? "]" : "}";
      i++;
      const items = [];
      space();
      if (text[i] === close) { i++; return items; }
      for (;;) {
        items.push(value());
        space();
        if (text[i] === ",") { i++; continue; }
        if (text[i] === close) { i++; return items; }
        fail("a malformed list");
      }
    }
    if (text.startsWith("<<", i)) {
      i += 2;
      space();
      if (text.startsWith(">>", i)) { i += 2; return ""; }
      const s = quoted('"');
      if (text.startsWith("/utf8", i)) i += 5;
      if (!text.startsWith(">>", i)) fail("a malformed binary");
      i += 2;
      return s;
    }
    if (c === "'") return quoted("'");
    if (/[-0-9]/.test(c)) {
      const m = /^-?[0-9]+(\.[0-9]+)?([eE][-+]?[0-9]+)?/.exec(text.slice(i));
      i += m[0].length;
      return Number(m[0]);
    }
    const a = atomName();
    if (a === "undefined") return null;
    if (a === "true") return true;
    if (a === "false") return false;
    return a;
  };
  const atomName = () => {
    const m = /^[a-zA-Z_][a-zA-Z0-9_@]*/.exec(text.slice(i));
    if (!m) fail("no term");
    i += m[0].length;
    return m[0];
  };
  const v = value();
  space();
  if (i < text.length) fail("text after the term");
  return v;
}

function sorted(v) {
  if (Array.isArray(v)) return v.map(sorted);
  if (v !== null && typeof v === "object") {
    const out = {};
    for (const k of Object.keys(v).sort()) out[k] = sorted(v[k]);
    return out;
  }
  return v;
}

const read = process.argv.includes("--json") ? JSON.parse : parse;
for (const line of lines) process.stdout.write(JSON.stringify(sorted(read(line))) + "\n");
