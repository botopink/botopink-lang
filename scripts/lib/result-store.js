// result-store.js — the cell-result store of the gate's shell runners
// (tests/language/run.sh, scripts/check-docs.sh); decisions 229 and 249 of
// 1.0.11-beta, front 00-gate/133-gate-speed. `botopink-lib-test` keeps the same
// store (modules/lib-test-runner/src/result_store.zig) and takes the compiler and
// toolchain part of its keys from `compiler` below, so the two cannot disagree.
//
// A warm run may answer a cell from a stored PASS only when the cell's key is
// equal. The key is the SHA-256 of everything the cell reads:
//
//   - the compiler (decision 249): its build configuration (`botopink --version`'s
//     `build:` line — Zig version, optimize mode, target triple) and its SOURCES,
//     partitioned by backend: the file set `modules/source-stamp/src/root.zig`
//     hashes (the files the binaries are built from), each file in the key of
//     every cell unless `modules/compiler-core/src/codegen/backend-partition.txt`
//     assigns it to one target, when it is in that target's keys only. A job
//     whose label names no target (`*`: `botopink check`) holds every target's
//     files. The binary must be built from exactly these sources (its `build:`
//     hash equals the checkout's), and the partition must pass its audit
//     (`auditPartition`), or nothing of the run is read or written;
//   - the toolchain: `node --version`, the OTP release (`erl`: otp_release, the
//     erts version and the release's OTP_VERSION file), `wasmtime --version`,
//     the platform, and the environment variables a compiler, a runtime or a
//     test reads (`ENV_NAMES`) — every runtime in every key, whatever the
//     target: the comptime node is an `erl` on every target and `node` judges
//     the harness's JSON;
//   - the global inputs the caller names: files (the runner scripts) and trees
//     (the library roots), each by content;
//   - the cell's own inputs: files and whole directory trees by content, with
//     each path, each directory and each file's executable bit.
//
// Nothing decides what a change can affect: a key that differs in one byte runs
// the cell. Only passes are stored. A cell whose inputs cannot be enumerated
// with certainty is never stored, and its reason is printed: a symbolic link in
// a hashed tree (its target is outside the hash), a manifest dependency that
// resolves outside the cell (a `path` above it, any `git` dependency), and — for
// every cell of the run — a library root the compiler would find by walking up
// from the scratch directory (an ancestor holding `botopink.json`, `libs/` or
// `repository/`).
//
// Usage (every path absolute; ids are paths relative to --work):
//
//   node result-store.js keys --spec <file> --out <file> --base <dir> --compiler <botopink>
//        [--global-file <label>=<path>]… [--global-tree <label>=<dir>]…
//        [--global-text <text>] [--scratch <dir>]
//     spec: one `<id>\t<label>\t<input>[\t<input>…]` line per cell; the label's
//     first word is the target the job compiles for (`*`: none); an input is
//     a file or a directory relative to --base, written `<path>` or
//     `<name>=<path>` (the key carries the name, so a scratch directory's
//     number is not part of it; absent inputs are recorded as absent). The
//     id names the verdict file and is not part of the key. Writes
//     `<id>\t<key|->\t<reason>` per line.
//   node result-store.js lookup --store <dir> --keys <file> --work <dir> --out <file>
//     every keyed cell with an entry: its stored result is written to
//     <work>/<id> and the id listed in --out.
//   node result-store.js save --store <dir> --before <keys> --after <keys>
//        --work <dir> --hits <file> --pass <lines-ok|exists>
//     every cell that ran (not in --hits), whose key did not move during the
//     run, and whose result is a pass is written to the store. `lines-ok`: every
//     line of <work>/<id> has `ok` or `audit` in its third tab field;
//     `exists`: <work>/<id> exists. Entries unused for 7 days are deleted.
//   node result-store.js toolchain
//     prints the toolchain part of every key.
//   node result-store.js compiler --bin <botopink>
//     prints the compiler and toolchain part of every key: `why <reason>` when
//     nothing may be stored, else `build …`, `shared <hex>`, one `target <t>
//     <hex>` per target, then the toolchain (botopink-lib-test reads it).
//   node result-store.js source-hash --root <checkout>
//     prints the hash `source_stamp` computes over the checkout — the one a
//     binary built from it carries on its `build:` line.
"use strict";
const fs = require("fs");
const path = require("path");
const crypto = require("crypto");
const { spawnSync } = require("child_process");

const VERSION = "botopink result store v1";
const ENV_NAMES = [
    "BOTOPINK_LIB_ROOTS", "BPMP_HOME", "ERL_AFLAGS", "ERL_COMPILER_OPTIONS", "ERL_FLAGS",
    "ERL_LIBS", "ERL_ZFLAGS", "HOME", "LANG", "LC_ALL", "NODE_OPTIONS", "NODE_PATH", "TZ",
    "XDG_CACHE_HOME",
];
const OTP_PROBE = 'io:format("~s ~s ~s~n",[erlang:system_info(otp_release),erlang:system_info(version),code:root_dir()]), halt().';
const TTL_MS = 7 * 24 * 3600 * 1000;
const TARGETS = ["commonJS", "erlang", "beam", "wasm"];
const PARTITION = "modules/compiler-core/src/codegen/backend-partition.txt";
const STAMP = "modules/source-stamp/src/root.zig";

function sha256(data) { return crypto.createHash("sha256").update(data).digest("hex"); }

function firstLine(cmd, args) {
    const r = spawnSync(cmd, args, { encoding: "utf8" });
    if (r.error || r.status !== 0) return "absent";
    return (r.stdout.split("\n")[0] || "").trim() || "absent";
}

function toolchain() {
    const lines = [];
    lines.push(`platform ${process.platform} ${process.arch}`);
    lines.push(`node ${firstLine("node", ["--version"])}`);
    let otp = "absent";
    const probe = firstLine("erl", ["-noshell", "-eval", OTP_PROBE]);
    const m = /^(\S+) (\S+) (.+)$/.exec(probe);
    if (m) {
        let full = "absent";
        try { full = fs.readFileSync(path.join(m[3], "releases", m[1], "OTP_VERSION"), "utf8").trim(); } catch {}
        otp = `${m[1]} erts ${m[2]} full ${full}`;
    }
    lines.push(`otp ${otp}`);
    lines.push(`wasmtime ${firstLine("wasmtime", ["--version"])}`);
    for (const n of ENV_NAMES) lines.push(`env ${n}=${process.env[n] === undefined ? "<unset>" : process.env[n]}`);
    return lines.join("\n") + "\n";
}

class Unstorable extends Error {}

// The file set the binaries are built from — `source_stamp`'s, read from its
// own source so the two cannot drift: ROOTS under the checkout, every regular
// file but `*.md`, hidden directories and SKIP_DIRS left out.
function zigStrings(text, name) {
    const m = new RegExp(`pub const ${name} = \\[_\\]\\[\\]const u8\\{([^}]*)\\}`).exec(text);
    if (!m) throw new Unstorable(`${STAMP} declares no ${name}`);
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
    files.sort((a, b) => Buffer.compare(Buffer.from(a), Buffer.from(b)));
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
        if (!p || extra !== undefined) throw new Unstorable(`${PARTITION}:${i + 1} is not \`<target> <path>\``);
        if (kind === "dispatcher") { dispatcher = p; return; }
        if (!TARGETS.includes(kind)) throw new Unstorable(`${PARTITION}:${i + 1} names \`${kind}\`, which is no target`);
        if (own.has(p)) throw new Unstorable(`${PARTITION}:${i + 1} lists ${p} twice`);
        own.set(p, kind);
    });
    return { own, dispatcher };
}

// A listed file may be used only by files of its own target and the
// dispatcher: a shared file that imports and uses it makes the backend's bytes
// reach every target. Every `const X = @import("…")` (and every inline
// `@import("…").f`) of every `.zig` of the set is read; `_ = @import(…)` (a
// test reference) is not a use, nor an import whose name is never followed by
// a `.`.
function auditPartition(root, files, part) {
    const set = new Set(files);
    for (const p of part.own.keys()) if (!set.has(p)) throw new Unstorable(`${PARTITION} lists ${p}, which is not a compiler source`);
    if (part.dispatcher && !set.has(part.dispatcher)) throw new Unstorable(`${PARTITION} names the dispatcher ${part.dispatcher}, which is not a compiler source`);
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
            if (used) throw new Unstorable(`${f} uses ${target}, which ${PARTITION} gives to ${theirs} alone`);
        }
    }
}

// The compiler part of every key, from the binary the runner runs.
function compilerParts(bin) {
    const r = spawnSync(bin, ["--version"], { encoding: "utf8" });
    const line = r.status === 0 ? r.stdout.split("\n").find((l) => l.startsWith("build: ")) : undefined;
    if (!line) return { why: `\`${bin} --version\` prints no \`build:\` line` };
    const m = /^build: (zig \S+ \S+ \S+) ([0-9a-f]{64}) (.+)$/.exec(line);
    if (!m) return { why: `\`${bin} --version\` prints a \`build:\` line this script cannot read` };
    const [, build, built, root] = m;
    try {
        const files = sourceSet(root);
        const stamp = crypto.createHash("sha256"), shared = crypto.createHash("sha256");
        const per = Object.fromEntries(TARGETS.map((t) => [t, crypto.createHash("sha256")]));
        const part = readPartition(root);
        auditPartition(root, files, part);
        for (const f of files) {
            const bytes = fs.readFileSync(path.join(root, f));
            stamp.update(f); stamp.update(Buffer.from([0])); stamp.update(bytes); stamp.update(Buffer.from([0]));
            const h = per[part.own.get(f)] || shared;
            h.update(`${f} ${sha256(bytes)}\n`);
        }
        if (stamp.digest("hex") !== built)
            return { why: `${bin} was not built from the sources ${root} holds now (run zig build there)` };
        const targets = Object.fromEntries(TARGETS.map((t) => [t, per[t].digest("hex")]));
        return { build, shared: shared.digest("hex"), targets };
    } catch (e) {
        if (!(e instanceof Unstorable)) throw e;
        return { why: e.message };
    }
}

function sourceHash(root) {
    const stamp = crypto.createHash("sha256");
    for (const f of sourceSet(root)) {
        stamp.update(f); stamp.update(Buffer.from([0])); stamp.update(fs.readFileSync(path.join(root, f))); stamp.update(Buffer.from([0]));
    }
    return stamp.digest("hex");
}

function compilerText(c) {
    if (c.why) return `why ${c.why}\n`;
    return `build ${c.build}\nshared ${c.shared}\n` + TARGETS.map((t) => `target ${t} ${c.targets[t]}\n`).join("");
}

// The digest of a file or a directory tree. `skipBuild` leaves out `.git` and
// `.botopinkbuild` directories (a library root's VCS data and build caches,
// written by the runs themselves); a cell's tree is hashed whole.
function digest(p, rel, skipBuild) {
    let st;
    try { st = fs.lstatSync(p); } catch { return "absent"; }
    if (st.isSymbolicLink()) throw new Unstorable(`${rel} is a symbolic link`);
    if (st.isFile()) return `file ${st.mode & 0o111 ? "x" : "-"} ${sha256(fs.readFileSync(p))}`;
    if (!st.isDirectory()) throw new Unstorable(`${rel} is neither a file nor a directory`);
    const h = crypto.createHash("sha256");
    const walk = (dir, r) => {
        const names = fs.readdirSync(dir).sort();
        for (const name of names) {
            const full = path.join(dir, name), sub = r ? `${r}/${name}` : name;
            const s = fs.lstatSync(full);
            if (s.isSymbolicLink()) throw new Unstorable(`${rel}/${sub} is a symbolic link`);
            if (s.isDirectory()) {
                if (skipBuild && (name === ".git" || name === ".botopinkbuild")) continue;
                h.update(`D ${sub}\n`);
                walk(full, sub);
            } else if (s.isFile()) {
                h.update(`F ${sub} ${s.mode & 0o111 ? "x" : "-"} ${sha256(fs.readFileSync(full))}\n`);
            } else {
                throw new Unstorable(`${rel}/${sub} is neither a file nor a directory`);
            }
        }
    };
    walk(p, "");
    return `tree ${h.digest("hex")}`;
}

// Every manifest under a cell's directory: a `git` dependency, or a `path` one
// that leaves the directory, reads bytes outside the cell's hash.
function checkManifests(dir, rel) {
    const walk = (d) => {
        for (const name of fs.readdirSync(d)) {
            const full = path.join(d, name);
            const s = fs.lstatSync(full);
            if (s.isDirectory()) { walk(full); continue; }
            if (name !== "botopink.json") continue;
            let m;
            try { m = JSON.parse(fs.readFileSync(full, "utf8")); } catch { continue; }
            const deps = m && typeof m.dependencies === "object" && m.dependencies !== null && !Array.isArray(m.dependencies) ? m.dependencies : {};
            for (const [dep, spec] of Object.entries(deps)) {
                if (spec && typeof spec === "object" && spec.git !== undefined)
                    throw new Unstorable(`${rel}: dependency \`${dep}\` is a git dependency (resolved outside the cell)`);
                if (spec && typeof spec === "object" && typeof spec.path === "string") {
                    const target = path.resolve(d, spec.path);
                    if (target !== dir && !target.startsWith(dir + path.sep))
                        throw new Unstorable(`${rel}: dependency \`${dep}\` has a path outside the cell`);
                }
            }
        }
    };
    walk(dir);
}

function args(argv) {
    const o = { "global-file": [], "global-tree": [] };
    for (let i = 0; i < argv.length; i += 2) {
        const k = argv[i].replace(/^--/, ""), v = argv[i + 1];
        if (Array.isArray(o[k])) o[k].push(v); else o[k] = v;
    }
    return o;
}

function keys(o) {
    const head = [VERSION, toolchain()];
    let runReason = "";
    const compiler = compilerParts(o.compiler);
    if (compiler.why) runReason = compiler.why;
    else head.push(`build ${compiler.build}`, `shared ${compiler.shared}`);
    try {
        for (const g of o["global-file"]) {
            const at = g.indexOf("=");
            head.push(`global-file ${g.slice(0, at)} ${digest(g.slice(at + 1), g.slice(0, at), false)}`);
        }
        for (const g of o["global-tree"]) {
            const at = g.indexOf("=");
            head.push(`global-tree ${g.slice(0, at)} ${digest(g.slice(at + 1), g.slice(0, at), true)}`);
        }
    } catch (e) {
        if (!(e instanceof Unstorable)) throw e;
        runReason = e.message;
    }
    if (o["global-text"] !== undefined) head.push(`global-text ${o["global-text"]}`);
    if (!runReason && o.scratch) {
        // The compiler walks up from the scratch project for library roots
        // (`libs.resolveLibRoots`): one found there is read and never hashed.
        let d = path.resolve(o.scratch);
        for (;;) {
            for (const n of ["botopink.json", "libs", "repository"]) {
                if (fs.existsSync(path.join(d, n))) { runReason = `${path.join(d, n)} is a library root the compiler finds above the scratch directory`; break; }
            }
            if (runReason) break;
            const up = path.dirname(d);
            if (up === d) break;
            d = up;
        }
    }
    const headText = head.join("\n");
    const out = [];
    for (const line of fs.readFileSync(o.spec, "utf8").split("\n")) {
        if (!line) continue;
        const [id, label, ...inputs] = line.split("\t");
        if (runReason) { out.push(`${id}\t-\t${runReason}`); continue; }
        try {
            // The id names the verdict file, never the work: two cells with one
            // label and the same inputs are the same job.
            const target = label.split(" ")[0];
            if (target !== "*" && !TARGETS.includes(target)) throw new Error(`label ${label} names no target`);
            const parts = [headText, `label ${label}`];
            for (const t of target === "*" ? TARGETS : [target]) parts.push(`target ${t} ${compiler.targets[t]}`);
            for (const input of inputs) {
                const at = input.indexOf("=");
                const name = at < 0 ? input : input.slice(0, at), rel = at < 0 ? input : input.slice(at + 1);
                const full = path.join(o.base, rel);
                const d = digest(full, name, false);
                if (d.startsWith("tree ")) checkManifests(full, name);
                parts.push(`input ${name} ${d}`);
            }
            out.push(`${id}\t${sha256(parts.join("\n"))}\t`);
        } catch (e) {
            if (!(e instanceof Unstorable)) throw e;
            out.push(`${id}\t-\t${e.message}`);
        }
    }
    fs.writeFileSync(o.out, out.length ? out.join("\n") + "\n" : "");
}

function readKeys(file) {
    const m = new Map();
    for (const line of fs.readFileSync(file, "utf8").split("\n")) {
        if (!line) continue;
        const [id, key] = line.split("\t");
        m.set(id, key);
    }
    return m;
}

const entry = (store, key) => path.join(store, key.slice(0, 2), key);

function lookup(o) {
    const hits = [];
    for (const [id, key] of readKeys(o.keys)) {
        if (key === "-") continue;
        const e = entry(o.store, key);
        let data;
        try { data = fs.readFileSync(e); } catch { continue; }
        fs.mkdirSync(path.dirname(path.join(o.work, id)), { recursive: true });
        fs.writeFileSync(path.join(o.work, id), data);
        const now = new Date();
        try { fs.utimesSync(e, now, now); } catch {}
        hits.push(id);
    }
    fs.writeFileSync(o.out, hits.length ? hits.join("\n") + "\n" : "");
}

function save(o) {
    const before = readKeys(o.before), after = readKeys(o.after);
    const hits = new Set(fs.readFileSync(o.hits, "utf8").split("\n").filter(Boolean));
    let stored = 0, moved = 0;
    for (const [id, key] of before) {
        if (key === "-" || hits.has(id)) continue;
        if (after.get(id) !== key) { moved++; continue; }
        let data;
        try { data = fs.readFileSync(path.join(o.work, id)); } catch { continue; }
        if (o.pass === "lines-ok") {
            const lines = data.toString("utf8").split("\n").filter(Boolean);
            if (lines.length === 0 || !lines.every((l) => ["ok", "audit"].includes(l.split("\t")[2]))) continue;
        } else if (o.pass !== "exists") {
            throw new Error(`unknown --pass ${o.pass}`);
        }
        const e = entry(o.store, key);
        fs.mkdirSync(path.dirname(e), { recursive: true });
        const tmp = `${e}.${process.pid}.${crypto.randomBytes(4).toString("hex")}.tmp`;
        fs.writeFileSync(tmp, data);
        fs.renameSync(tmp, e);
        stored++;
    }
    // Entries no run has read or written for 7 days go.
    const cutoff = Date.now() - TTL_MS;
    let shards = [];
    try { shards = fs.readdirSync(o.store); } catch {}
    for (const s of shards) {
        const dir = path.join(o.store, s);
        let names = [];
        try { names = fs.readdirSync(dir); } catch { continue; }
        for (const n of names) {
            const f = path.join(dir, n);
            try { if (fs.statSync(f).mtimeMs < cutoff) fs.unlinkSync(f); } catch {}
        }
    }
    process.stdout.write(`${stored} ${moved}\n`);
}

const [cmd, ...rest] = process.argv.slice(2);
const o = args(rest);
switch (cmd) {
    case "toolchain": process.stdout.write(toolchain()); break;
    case "source-hash": process.stdout.write(`${sourceHash(o.root)}\n`); break;
    case "compiler": process.stdout.write(compilerText(compilerParts(o.bin)) + toolchain()); break;
    case "keys": keys(o); break;
    case "lookup": lookup(o); break;
    case "save": save(o); break;
    default: process.stderr.write(`result-store.js: unknown command ${cmd}\n`); process.exit(2);
}
