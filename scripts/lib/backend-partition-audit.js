// backend-partition-audit.js — the audit of
// `modules/compiler-core/src/codegen/backend-partition.txt` (decision 249): the
// list that says which compiler sources belong to ONE backend, read by the step
// gate's reach (`gate-mode.sh`) and by the code cache's fingerprint.
//
// A listed file may be imported and used only by files of its own target and by
// the list's `dispatcher`: a shared file that imports and uses it makes the
// backend's bytes reach every target, and the list would be wrong. Every
// `const X = @import("…")` (and every inline `@import("…").f`) of every `.zig`
// of the compiler's source set is read; `_ = @import(…)` (a test reference) is
// not a use, nor an import whose name is never followed by a `.`. A listed file
// that is not a compiler source, a line that is not `<target> <path>`, a path
// listed twice and a name that is no target fail too.
//
// Usage: node backend-partition-audit.js [--root <checkout>]
//   exits 0 and prints one summary line, or exits 1 naming the first fault.
"use strict";
const fs = require("fs");
const path = require("path");

const TARGETS = ["commonJS", "erlang", "beam", "wasm"];
const PARTITION = "modules/compiler-core/src/codegen/backend-partition.txt";
const STAMP = "modules/source-stamp/src/root.zig";

class Fault extends Error {}

// The file set the binaries are built from — `source_stamp`'s, read from its
// own source so the two cannot drift: ROOTS under the checkout, every regular
// file but `*.md`, hidden directories and SKIP_DIRS left out.
function zigStrings(text, name) {
    const m = new RegExp(`pub const ${name} = \\[_\\]\\[\\]const u8\\{([^}]*)\\}`).exec(text);
    if (!m) throw new Fault(`${STAMP} declares no ${name}`);
    return [...m[1].matchAll(/"([^"]*)"/g)].map((x) => x[1]);
}
function sourceSet(root) {
    const text = fs.readFileSync(path.join(root, STAMP), "utf8");
    const roots = zigStrings(text, "ROOTS"), skip = new Set(zigStrings(text, "SKIP_DIRS"));
    const files = [];
    const collect = (rel) => {
        for (const e of fs.readdirSync(path.join(root, rel), { withFileTypes: true })) {
            const child = `${rel}/${e.name}`;
            if (e.isDirectory()) { if (!e.name.startsWith(".") && !skip.has(e.name)) collect(child); }
            else if (e.isFile() && !e.name.endsWith(".md")) files.push(child);
        }
    };
    for (const r of roots) {
        let st;
        try { st = fs.statSync(path.join(root, r)); } catch { continue; }
        if (st.isDirectory()) collect(r); else if (st.isFile()) files.push(r);
    }
    return files;
}

// The partition: `<target> <path>` lines, and the one `dispatcher <path>`.
function readPartition(root) {
    const own = new Map();
    let dispatcher = null;
    const text = fs.readFileSync(path.join(root, PARTITION), "utf8");
    text.split("\n").forEach((raw, i) => {
        const line = raw.trim();
        if (!line || line.startsWith("#")) return;
        const [kind, p, extra] = line.split(/\s+/);
        if (!p || extra !== undefined) throw new Fault(`${PARTITION}:${i + 1} is not \`<target> <path>\``);
        if (kind === "dispatcher") { dispatcher = p; return; }
        if (!TARGETS.includes(kind)) throw new Fault(`${PARTITION}:${i + 1} names \`${kind}\`, which is no target`);
        if (own.has(p)) throw new Fault(`${PARTITION}:${i + 1} lists ${p} twice`);
        own.set(p, kind);
    });
    return { own, dispatcher };
}

function auditPartition(root, files, part) {
    const set = new Set(files);
    for (const p of part.own.keys()) if (!set.has(p)) throw new Fault(`${PARTITION} lists ${p}, which is not a compiler source`);
    if (part.dispatcher && !set.has(part.dispatcher)) throw new Fault(`${PARTITION} names the dispatcher ${part.dispatcher}, which is not a compiler source`);
    for (const f of files) {
        if (!f.endsWith(".zig")) continue;
        const text = fs.readFileSync(path.join(root, f), "utf8");
        const mine = part.own.get(f);
        for (const m of text.matchAll(/@import\("([^"]+\.zig)"\)/g)) {
            const target = path.posix.normalize(path.posix.join(path.posix.dirname(f), m[1]));
            const theirs = part.own.get(target);
            if (theirs === undefined || theirs === mine || f === part.dispatcher) continue;
            const before = text.slice(0, m.index), after = text.slice(m.index + m[0].length);
            if (/_\s*=\s*$/.test(before)) continue; // `_ = @import(…)`
            const bound = /(?:pub\s+)?const\s+(\w+)\s*=\s*$/.exec(before);
            let used = true;
            if (bound && !/pub\s+const\s+\w+\s*=\s*$/.test(before)) {
                used = new RegExp(`\\b${bound[1]}\\.`).test(text.slice(0, m.index - bound[0].length) + after);
            }
            if (used) throw new Fault(`${f} uses ${target}, which ${PARTITION} gives to ${theirs} alone`);
        }
    }
}

const at = process.argv.indexOf("--root");
const root = path.resolve(at < 0 ? path.join(__dirname, "..", "..") : process.argv[at + 1]);
try {
    const files = sourceSet(root);
    const part = readPartition(root);
    auditPartition(root, files, part);
    console.log(`backend partition: ${part.own.size} files listed, audited against ${files.length} compiler sources`);
} catch (e) {
    if (!(e instanceof Fault)) throw e;
    console.error(`backend partition audit: ${e.message}`);
    process.exit(1);
}
