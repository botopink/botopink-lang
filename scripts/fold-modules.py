#!/usr/bin/env python3
"""Fold a conformance module into one package that loads its cases (decisions 789, 982; B-157 piece 5).

A module of `conformance/modules/` in piece 4's layout (decision 779) holds `run/` (the printing
cases, one program), `refused/` (the refused cases, one build, one `.snap` per case) and
`cells/<case>/` (full cells). Folded, it is (982 (5)):

    <module>/botopink.json             { "name": "<module>" }
    <module>/src/main.bp               789 (4)'s `runCase(comptime name)` and a top-level
                                       `comptime { runCase("<case>"); … }`
    <module>/cases/<case>/botopink.json   { "name": "<case>" } (a folded cell keeps its own)
    <module>/cases/<case>/src/main.bp     the case's program (a running case's `runCase()` its `main`)
    <module>/snapshot/output/main.snap    the module's one answer

A case moves only when its lines after `== <case>` equal its old records byte for byte on every
target (789 (6)): a run case's `out` lines, a refused case's `refused` / `at` / `label` records (the
`at` path relative to the case, 982 (4)), a cell's `out` / `refused` / `at` / `label` / `abort`
records. `run/` and `refused/` fold whole or not at all; a cell folds alone, and one that cannot —
a departure by target, narrowed `"targets"`, `deps/`, a record of another kind, a different answer —
stays `cells/<case>/` (781 (5)).

    fold-modules.py try   [--botopink <bin>] [--keep <dir>] <module>...   build and compare, change nothing
    fold-modules.py apply [--botopink <bin>] <module>...                  fold in place (git mv), what `try` proves
    fold-modules.py list                                                  the modules still holding run/, refused/ or cells/
    fold-modules.py reshape [--botopink <bin>] <module>...                a folded module into 989's self-checking shape

The four targets are run with `botopink run --target <t>` in the folded copy; stdout is the answer.
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HEADER = "botopink-cell 1"
TARGETS = ["commonJS", "erlang", "beam", "wasm"]
RUN_TIMEOUT = 900
FOLDABLE_CELL_RECORDS = {"out", "refused", "at", "label", "abort"}
MODULES = "conformance/modules"

TEMPLATE_HEAD = '''//// The module's one package (decisions 789 (4), 982 (5)): each case is a package under `cases/`,
//// loaded at build by `runCase`; a refused case prints its refusals, a running one runs its `main`.

import {compiler, io.terminal.print} from "std";

fn runCase(comptime name: string) -> void {
    print("== " + name + " comptime");
    val loaded = try comptime compiler.load("cases/" + name) catch { r ->
        compiler.init({ ->
            print("== " + name);
            for (r.diagnostics) { d ->
                val bracket = d.code != "" && !d.message.startsWith(d.code + ":");
                print(if (bracket) "refused error[" + d.code + "]: " + d.message else "refused error: " + d.message);
                print("at " + d.file + ":" + d.line.toString() + ":" + d.column.toString());
                if (d.label) { l -> print("label " + l); }
            }
        });
        return;
    };
    compiler.init({ ->
        print("== " + name);
        try loaded.run() catch { f -> print("abort " + f.message) }
    });
}

comptime {
'''
TEMPLATE_TAIL = '''}

pub fn main() -> void {}
'''


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def write(p, text):
    os.makedirs(os.path.dirname(p) or ".", exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(text)


def records(snap_text):
    """[(kind, rest)] of a `.snap`, the header dropped."""
    lines = snap_text.split("\n")
    if not lines or lines[0] != HEADER:
        raise ValueError("not a cell snapshot")
    out = []
    for line in lines[1:]:
        if line == "":
            continue
        kind, _, rest = line.partition(" ")
        out.append((kind, rest))
    return out


def run_order(module):
    """The run package's cases in its `main`'s call order."""
    main = read(os.path.join(module, "run", "src", "main.bp"))
    return re.findall(r"^\s*cases\.([a-z0-9_]+)\.runCase\(\);", main, re.M)


def mod_list(path):
    return re.findall(r"^pub mod ([a-z0-9_]+);", read(path), re.M)


class Case:
    def __init__(self, name, kind, src_dir, files, expected, manifest=None, why=None):
        self.name = name
        self.kind = kind            # "run" | "refused" | "cell"
        self.src_dir = src_dir      # where its files are now
        self.files = files          # [(from, to)] relative: to under cases/<name>/
        self.expected = expected    # [line] the block after `== <name>`; None for a run case
        self.manifest = manifest    # the folded case's botopink.json text
        self.why = why              # why it cannot fold, or None


def project_at(rest, case, case_prefix):
    """An old `at` record's path moved to the case's own root (982 (4))."""
    path, sep, place = rest.partition(":")
    if case_prefix and path.startswith(case_prefix):
        tail = path[len(case_prefix):]
        path = "src/main.bp" if tail == "mod.bp" else "src/" + tail
    return path + sep + place


def case_files(dir_, entry_from):
    """[(from, to)] of a run / refused case's directory: `mod.bp` → `src/main.bp`, `docs.md` at the
    case's root, every other file under `src/`."""
    out = []
    for root, _, fs in os.walk(dir_):
        for f in fs:
            full = os.path.join(root, f)
            rel = os.path.relpath(full, dir_)
            if ".botopinkbuild" in rel.split(os.sep):
                continue
            if rel == entry_from:
                out.append((full, "src/main.bp"))
            elif rel == "docs.md":
                out.append((full, "docs.md"))
            else:
                out.append((full, "src/" + rel))
    return sorted(out)


def gather(module):
    cases = []
    run = os.path.join(module, "run")
    if os.path.isdir(run):
        for c in run_order(module):
            d = os.path.join(run, "src", "cases", c)
            why = None
            text = read(os.path.join(d, "mod.bp"))
            if re.search(r"^\s*(pub\s+)?fn main\(", text, re.M):
                why = "declares its own main"
            cases.append(Case(c, "run", d, case_files(d, "mod.bp"), None, '{ "name": "%s" }\n' % c, why))
    refused = os.path.join(module, "refused")
    if os.path.isdir(refused):
        for c in mod_list(os.path.join(refused, "src", "cases", "mod.bp")):
            d = os.path.join(refused, "src", "cases", c)
            snap = os.path.join(refused, "snapshot", "output", "cases", c, "mod.snap")
            why, expected = None, []
            prefix = "src/cases/%s/" % c
            for kind, rest in records(read(snap)):
                if kind == "refused":
                    expected.append("refused " + rest)
                elif kind == "at":
                    expected.append("at " + project_at(rest, c, prefix))
                elif kind == "label":
                    expected.append("label " + rest)
                else:
                    why = "a `%s` record" % kind
            if os.path.isdir(os.path.join(refused, "snapshot", "targets")):
                why = why or "the refused package departs by target"
            cases.append(Case(c, "refused", d, case_files(d, "mod.bp"), expected, '{ "name": "%s" }\n' % c, why))
    cells = os.path.join(module, "cells")
    if os.path.isdir(cells):
        for c in sorted(os.listdir(cells)):
            d = os.path.join(cells, c)
            if not os.path.isdir(d):
                continue
            why, expected, manifest = None, [], None
            mpath = os.path.join(d, "botopink.json")
            try:
                m = json.loads(read(mpath))
                manifest = read(mpath)
                if "targets" in m:
                    why = "narrowed targets"
                if m.get("dependencies"):
                    why = why or "dependencies"
                if set(m) - {"name"}:
                    why = why or "manifest keys " + ",".join(sorted(set(m) - {"name"}))
            except (OSError, ValueError):
                why = "no readable botopink.json"
            for extra in ("deps", "snapshot/targets", "draft", "cases"):
                if os.path.exists(os.path.join(d, extra)):
                    why = why or "holds " + extra
            snap = os.path.join(d, "snapshot", "output", "main.snap")
            if not os.path.exists(snap):
                why = why or "no main.snap"
                outs = []
            else:
                snaps = [f for f in os.listdir(os.path.join(d, "snapshot", "output"))]
                if snaps != ["main.snap"]:
                    why = why or "more than one snapshot"
                outs = records(read(snap))
            for kind, rest in outs:
                if kind not in FOLDABLE_CELL_RECORDS:
                    why = why or "a `%s` record" % kind
                elif kind == "out":
                    expected.append(rest)
                else:
                    expected.append(kind + " " + rest)
            files = []
            for root, dirs, fs in os.walk(d):
                rel_root = os.path.relpath(root, d)
                if rel_root.split(os.sep)[0] in ("snapshot", ".botopinkbuild"):
                    continue
                for f in fs:
                    full = os.path.join(root, f)
                    rel = os.path.relpath(full, d)
                    if rel == "botopink.json":
                        continue
                    files.append((full, rel))
            if not os.path.exists(os.path.join(d, "src", "main.bp")):
                why = why or "no src/main.bp"
            cases.append(Case(c, "cell", d, sorted(files), expected, manifest, why))
    return cases


def rewrite_case_source(text, case):
    """A run / refused case's own path prefix (`cases.<case>.`) dropped: its modules are its
    package's now; a running case's `runCase()` is its `main`."""
    text = text.replace("cases.%s." % case.name, "")
    if case.kind == "run":
        text = re.sub(r"^pub fn runCase\(\) -> void", "pub fn main() -> void", text, flags=re.M)
    return text


def build_copy(module, cases, dest):
    """The folded module of `cases` written to `dest`."""
    name = os.path.basename(os.path.normpath(module))
    write(os.path.join(dest, "botopink.json"), '{ "name": "%s" }\n' % name)
    body = "".join('    runCase("%s");\n' % c.name for c in cases)
    write(os.path.join(dest, "src", "main.bp"), TEMPLATE_HEAD + body + TEMPLATE_TAIL)
    for c in cases:
        root = os.path.join(dest, "cases", c.name)
        write(os.path.join(root, "botopink.json"), c.manifest)
        for frm, to in c.files:
            target = os.path.join(root, to)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            if frm.endswith(".bp") and c.kind != "cell":
                write(target, rewrite_case_source(read(frm), c))
            else:
                shutil.copyfile(frm, target)


def run_targets(botopink, dest):
    """{target: stdout lines | error text}."""
    got = {}
    for t in TARGETS:
        shutil.rmtree(os.path.join(dest, ".botopinkbuild"), ignore_errors=True)
        try:
            p = subprocess.run([botopink, "run", "--target", t], cwd=dest, capture_output=True,
                               text=True, timeout=RUN_TIMEOUT)
        except subprocess.TimeoutExpired:
            got[t] = "timeout"
            continue
        if p.returncode != 0:
            got[t] = "exit %d: %s" % (p.returncode, (p.stderr.strip().splitlines() or [""])[-1])
            continue
        got[t] = p.stdout.split("\n")
    return got


def blocks(lines, names):
    """{case: [line]} — each case's lines after `== <case>`, the build's `== <case> comptime` lines
    and anything before the first block dropped."""
    out, cur = {}, None
    wanted = set(names)
    for line in lines:
        if line.startswith("== ") and line.endswith(" comptime") and line[3:-9] in wanted:
            continue
        if line.startswith("== ") and line[3:] in wanted:
            cur = line[3:]
            out[cur] = []
            continue
        if cur is not None:
            out[cur].append(line)
    for k in out:
        while out[k] and out[k][-1] == "":
            out[k].pop()
    return out


def compare(module, cases, got):
    """(ok cases, {case: why}) — run cases as one group against run/'s main.snap."""
    bad = {}
    names = [c.name for c in cases]
    per = {}
    for t, lines in got.items():
        if isinstance(lines, str):
            return [], {c.name: "%s: %s" % (t, lines) for c in cases}
        per[t] = blocks(lines, names)
    run_cases = [c for c in cases if c.kind == "run"]
    if run_cases:
        old = [rest for kind, rest in records(read(os.path.join(module, "run", "snapshot", "output", "main.snap")))
               if kind == "out"]
        kinds = {kind for kind, _ in records(read(os.path.join(module, "run", "snapshot", "output", "main.snap")))}
        for t in TARGETS:
            joined = [l for c in run_cases for l in per[t].get(c.name, ["<missing>"])]
            if kinds - {"out"}:
                for c in run_cases:
                    bad[c.name] = "run/'s main.snap holds %s records" % ",".join(sorted(kinds - {"out"}))
            elif joined != old:
                for c in run_cases:
                    bad.setdefault(c.name, "%s: the run cases' lines differ from run/'s main.snap" % t)
    for c in cases:
        if c.kind == "run":
            continue
        for t in TARGETS:
            if per[t].get(c.name) != c.expected:
                bad.setdefault(c.name, "%s: %r != %r" % (t, per[t].get(c.name), c.expected))
    return [c for c in cases if c.name not in bad], bad


def attempt(module, cases, botopink, keep=None):
    """(ok, {case: why}) of one folded copy of `cases`."""
    dest = tempfile.mkdtemp(prefix="fold-")
    try:
        build_copy(module, cases, dest)
        got = run_targets(botopink, dest)
        if keep:
            shutil.rmtree(keep, ignore_errors=True)
            shutil.copytree(dest, keep, ignore=shutil.ignore_patterns(".botopinkbuild"))
        return got, compare(module, cases, got)
    finally:
        shutil.rmtree(dest, ignore_errors=True)


def fits(module, base, more, botopink):
    """Whether `base + more` folds: every target builds and runs, every case answers as before."""
    got, (ok, bad) = attempt(module, base + more, botopink)
    return not bad and len(ok) == len(base) + len(more), bad


def plan(module, botopink, keep=None):
    """(foldable cases, {case: why}) for `module`, proved by folded copies: run/ and refused/
    first, each whole (a package one of whose cases cannot fold stays a package); then the cells,
    added in batches to what already folds, a batch that does not fit split in halves until the
    cell that keeps it out is alone (a cell can fail beside others it passes alone with: two
    loaded packages meeting in one program)."""
    cases = gather(module)
    whys = {c.name: c.why for c in cases if c.why}
    for kind in ("run", "refused"):
        if any(c.kind == kind and c.why for c in cases):
            for c in cases:
                if c.kind == kind:
                    whys.setdefault(c.name, "its %s/ package keeps a case that cannot fold" % kind)
    base = []
    for kind in ("run", "refused"):
        group = [c for c in cases if c.kind == kind and c.name not in whys]
        if not group:
            continue
        good, bad = fits(module, base, group, botopink)
        if good:
            base += group
        else:
            for c in group:
                whys.setdefault(c.name, bad.get(c.name) or "its %s/ package differs as a whole" % kind)

    def add(batch):
        nonlocal base
        if not batch:
            return
        good, bad = fits(module, base, batch, botopink)
        if good:
            base += batch
        elif len(batch) == 1:
            whys[batch[0].name] = bad.get(batch[0].name) or "differs beside the folded cases"
        else:
            half = len(batch) // 2
            add(batch[:half])
            add(batch[half:])

    add([c for c in cases if c.kind == "cell" and c.name not in whys])
    if base and keep:
        attempt(module, base, botopink, keep)
    # The module's order: run cases, refused cases, cells, as gathered.
    order = {c.name: i for i, c in enumerate(cases)}
    return sorted(base, key=lambda c: order[c.name]), whys


def snapshot_of(module, cases, botopink):
    """The folded module's `main.snap` from a clean copy, as `cell check` records a package that
    prints: its stdout lines as `out` records, the build's `== <case> comptime` lines left to the
    program's `build` records. Every target must print the same lines; anything else raises."""
    dest = tempfile.mkdtemp(prefix="fold-snap-")
    try:
        build_copy(module, cases, dest)
        got = run_targets(botopink, dest)
    finally:
        shutil.rmtree(dest, ignore_errors=True)
    answers = {}
    for t, lines in got.items():
        if isinstance(lines, str):
            raise RuntimeError("%s: %s" % (t, lines))
        body = [l for l in lines if not (l.startswith("== ") and l.endswith(" comptime"))]
        while body and body[-1] == "":
            body.pop()
        answers[t] = body
    if len({tuple(v) for v in answers.values()}) != 1:
        raise RuntimeError("the targets print different lines")
    return HEADER + "\n" + "".join("out %s\n" % l for l in answers["erlang"])


def git(*args, cwd=None):
    subprocess.check_call(["git"] + list(args), cwd=cwd)


def apply(module, botopink):
    ok, whys = plan(module, botopink)
    if not ok:
        print("%s: nothing folds" % module)
        for k, v in sorted(whys.items()):
            print("  stays %s: %s" % (k, v))
        return 1
    name = os.path.basename(os.path.normpath(module))
    snap = snapshot_of(module, ok, botopink)
    # The folded files written in place; the moved ones by `git mv` so their history follows.
    for c in ok:
        root = os.path.join(module, "cases", c.name)
        os.makedirs(root, exist_ok=True)
        for frm, to in c.files:
            target = os.path.join(root, to)
            os.makedirs(os.path.dirname(target), exist_ok=True)
            git("mv", frm, target)
            if target.endswith(".bp") and c.kind != "cell":
                write(target, rewrite_case_source(read(target), c))
        write(os.path.join(root, "botopink.json"), c.manifest)
        if c.kind == "cell":
            git("rm", "-q", "-r", "--cached", "--ignore-unmatch", os.path.join(c.src_dir, "botopink.json"))
            shutil.rmtree(c.src_dir, ignore_errors=True)
    write(os.path.join(module, "botopink.json"), '{ "name": "%s" }\n' % name)
    body = "".join('    runCase("%s");\n' % c.name for c in ok)
    write(os.path.join(module, "src", "main.bp"), TEMPLATE_HEAD + body + TEMPLATE_TAIL)
    write(os.path.join(module, "snapshot", "output", "main.snap"), snap)
    # run/ and refused/ fold whole (`plan`): a package one of whose cases folded is gone.
    for pkg in ("run", "refused"):
        p = os.path.join(module, pkg)
        if os.path.isdir(p) and any(c.kind == pkg for c in ok):
            subprocess.call(["git", "rm", "-q", "-r", "--ignore-unmatch", p])
            shutil.rmtree(p, ignore_errors=True)
    cells = os.path.join(module, "cells")
    if os.path.isdir(cells) and not os.listdir(cells):
        os.rmdir(cells)
    rewrite_refs(module, ok)
    git("add", "-A", module, "conformance/docs.md")
    print("%s: folded %d case(s)" % (module, len(ok)))
    for k, v in sorted(whys.items()):
        print("  stays %s: %s" % (k, v))
    return 0


def old_paths(c):
    """[(old, new)] of a folded case's paths, relative to its module: its directory and its entry."""
    if c.kind == "cell":
        return [("cells/%s/src/main.bp" % c.name, "cases/%s/src/main.bp" % c.name), ("cells/%s" % c.name, "cases/%s" % c.name)]
    return [("%s/src/cases/%s/mod.bp" % (c.kind, c.name), "cases/%s/src/main.bp" % c.name),
            ("%s/src/cases/%s" % (c.kind, c.name), "cases/%s" % c.name)]


def rewrite_refs(module, ok):
    """The module's `docs.md` links and `conformance/docs.md`'s `<!-- example: … -->` markers moved
    to the folded paths; any other file still naming an old path is printed."""
    rel_module = os.path.relpath(module, MODULES)
    pairs = [p for c in ok for p in old_paths(c)]
    docs = os.path.join(module, "docs.md")
    if os.path.exists(docs):
        text = read(docs)
        for o, n in pairs:
            text = re.sub(r"(?<![\w/])" + re.escape(o) + r"(?=[)/\s\]]|$)", n, text)
        write(docs, text)
    ref = "conformance/docs.md"
    if os.path.exists(ref):
        text = read(ref)
        for o, n in pairs:
            text = text.replace("modules/%s/%s -->" % (rel_module, o), "modules/%s/%s -->" % (rel_module, n))
            text = text.replace("modules/%s/%s/" % (rel_module, o), "modules/%s/%s/" % (rel_module, n))
        write(ref, text)
    # Every other file under conformance/ (this script's, decision 988 (5)) names the new paths too;
    # a file elsewhere — the compiler's comments, build.zig — is printed for its owner.
    needles = ["modules/%s/%s" % (rel_module, o) for o, _ in pairs]
    grep = ["git", "grep", "-l", "-F"] + sum([["-e", x] for x in needles], [])
    for h in subprocess.run(grep + ["--", "conformance"], capture_output=True, text=True).stdout.split():
        text = read(h)
        for o, n in pairs:
            text = re.sub(re.escape("modules/%s/%s" % (rel_module, o)) + r"(?![\w])", "modules/%s/%s" % (rel_module, n), text)
        write(h, text)
    for h in subprocess.run(grep + ["--", ".", ":!conformance"], capture_output=True, text=True).stdout.split():
        print("  still names an old path: %s" % h)


def modules():
    out = []
    for root in (MODULES, os.path.join(MODULES, "decisions-taken")):
        for m in sorted(os.listdir(root)):
            p = os.path.join(root, m)
            if m == "decisions-taken" or not os.path.isdir(p):
                continue
            if any(os.path.isdir(os.path.join(p, k)) for k in ("run", "refused", "cells")):
                out.append(p)
    return out


# ── reshape: a folded module into 989's self-checking shape (decision 990 piece 6) ──────────

SELF_CHECK_HEAD = '''//// A module checking itself (decision 989): each case is a package under `cases/`, loaded at build,
//// run in this program and compared with its section of `snapshot/main.snap`; a difference writes
//// `snapshot/main.snap.new` and `main` answers `Error`. Nothing here accepts a candidate.

import {compiler, io.terminal.print} from "std";
import {adapter, candidate, observe, records} from "conformance-lib";

/// The snapshot, read as a build input (decision 989 (5)).
val accepted: string = @embed("snapshot/main.snap").text();

/// What each case answered, in the order the cases ran.
var answers: observe.Observed[] = [];

/// One case, expanded where `main` calls it (decisions 808 (2), 998 (5)): a refused load answers
/// its diagnostics, a loaded one runs and answers its output — awaited in `main`'s `async` body
/// when the case's own `main` is `async` (`mainAsync()`, read at build).
fn runCase(comptime name: string) -> void {
    val loaded = try comptime compiler.load("cases/" + name) catch { r ->
        compiler.init({ ->
            var refusals: records.Refusal[] = [];
            for (r.diagnostics) { d ->
                refusals.push(observe.refusalOf(d.code, d.message, d.file, d.line, d.column, d.label, adapter.frames(d)));
            }
            answers.push(observe.refusedAnswer(name, adapter.buildOutput(r.module), refusals));
        });
        return;
    };
    if (comptime loaded.mainAsync())
        compiler.init({ async ->
            val ran = adapter.ranOf(await loaded.run());
            answers.push(observe.ranAnswer(name, adapter.buildOutput(loaded), ran.printed, ran.failed, ran.failure));
        })
    else
        compiler.init({ ->
            val ran = adapter.ranOf(loaded.run());
            answers.push(observe.ranAnswer(name, adapter.buildOutput(loaded), ran.printed, ran.failed, ran.failure));
        });
}

pub async fn main() -> Async<Result<void, string>> {
'''
SELF_CHECK_TAIL = '''    return candidate.finish(accepted, answers, adapter.target(), (comptime compiler.src()).root);
}
'''
WORKSPACE = os.path.join(MODULES, "botopink.json")
REFUSAL_PREFIXES = ("refused ", "at ", "label ", "from ")


def old_sections(module):
    """{case: [line]} of a folded module's piece-4 `snapshot/output/main.snap` (`out == <case>` then
    the case's printed lines), and the cases in order."""
    text = read(os.path.join(module, "snapshot", "output", "main.snap"))
    order, out, cur = [], {}, None
    for kind, rest in records(text):
        if kind == "out" and rest.startswith("== "):
            cur = rest[3:]
            order.append(cur)
            out[cur] = []
        elif cur is not None:
            out[cur].append((kind, rest))
    return order, out


def readings(lines):
    """The record bodies an old block can mean: every line printed (`out`), or a refusal's
    `refused` / `at` / `label` / `from` records and a run's `abort` (what 789 (4)'s template printed)."""
    plain = ["out " + r if k == "out" else k + " " + r for k, r in lines]
    rec = []
    for k, r in lines:
        if k == "out" and (r.startswith(REFUSAL_PREFIXES) or r.startswith("abort ")):
            rec.append(r)
        else:
            rec.append("out " + r if k == "out" else k + " " + r)
    return [plain, rec]


def new_sections(text):
    """{(case, target or None): [record line]} of a `botopink-cell 2` file."""
    out, cur = {}, None
    for line in text.split("\n")[1:]:
        if line.startswith("== "):
            head = line[3:]
            name, _, tgt = head.partition(" on ")
            cur = (name, tgt or None)
            out[cur] = []
        elif cur is not None and line != "":
            out[cur].append(line)
    return out


class Workspace:
    """`conformance/modules/botopink.json` narrowed to `*/cases/*` while a module runs in the tree
    (its `*/run` / `*/refused` / `*/cells/*` members are refused until piece 6's root package), put
    back after; never committed."""
    def __enter__(self):
        self.text = read(WORKSPACE)
        d = json.loads(self.text)
        # Since piece 6 the root is a package with no `workspaces`: a module runs in place.
        if "workspaces" not in d:
            self.text = None
            return
        d["workspaces"] = ["*/cases/*", "decisions-taken/*/cases/*"]
        write(WORKSPACE, json.dumps(d) + "\n")
    def __exit__(self, *a):
        if self.text is not None:
            write(WORKSPACE, self.text)


def run_in_place(botopink, module, target):
    shutil.rmtree(os.path.join(module, ".botopinkbuild"), ignore_errors=True)
    try:
        p = subprocess.run([botopink, "run", "--target", target], cwd=module, capture_output=True, text=True, timeout=RUN_TIMEOUT)
    except subprocess.TimeoutExpired:
        return "timeout"
    return p


def reshape(module, botopink):
    """Rewrite a folded module into 989's shape, proved: its candidate on erlang must equal, case by
    case, its old answer (789 (6): the `build` records are new and set aside), and commonJS and beam
    must then answer it with no `.new`. Anything else puts the module back as it was."""
    if not os.path.exists(os.path.join(module, "snapshot", "output", "main.snap")) or not os.path.isdir(os.path.join(module, "cases")):
        return "skip (not a folded module)"
    order, old = old_sections(module)
    name = os.path.basename(os.path.normpath(module))
    depth = os.path.relpath(MODULES, module).count("..") + 1
    lib = "/".join([".."] * depth) + "/lib"
    snap = os.path.join(module, "snapshot", "main.snap")
    new = snap + ".new"
    keep = {f: read(os.path.join(module, f)) for f in ("botopink.json", "src/main.bp")}
    write(os.path.join(module, "botopink.json"), json.dumps({"name": name, "dependencies": {"conformance-lib": {"path": lib}}}) + "\n")
    write(os.path.join(module, "src", "main.bp"), SELF_CHECK_HEAD + "".join('    runCase("%s");\n' % c for c in order) + SELF_CHECK_TAIL)
    write(snap, HEADER.replace("1", "2") + "\n")
    why = None
    with Workspace():
        p = run_in_place(botopink, module, "erlang")
        if p == "timeout" or not os.path.exists(new):
            why = "erlang: no candidate (%s)" % ("timeout" if p == "timeout" else (p.stderr.strip().splitlines() or ["exit %d" % p.returncode])[-1][:160])
        else:
            cand = read(new)
            got = new_sections(cand)
            for c in order:
                body = [l for l in got.get((c, None), ["<missing>"]) if not l.startswith("build ") and l != "build"]
                if body not in readings(old[c]):
                    why = "%s: %r not %r" % (c, body[:4], readings(old[c])[1][:4])
                    break
            if any(t for (_, t) in got):
                why = why or "the candidate holds a departure"
            if not why:
                write(snap, cand)
                os.remove(new)
                for t in ("commonJS", "beam"):
                    q = run_in_place(botopink, module, t)
                    if os.path.exists(new):
                        why = "%s: answers otherwise (%s)" % (t, read(new)[:200].replace("\n", " | "))
                        break
                    if q == "timeout":
                        why = t + ": timeout"
                        break
    shutil.rmtree(os.path.join(module, ".botopinkbuild"), ignore_errors=True)
    if why:
        for f, text in keep.items():
            write(os.path.join(module, f), text)
        for f in (snap, new):
            if os.path.exists(f):
                os.remove(f)
        return "stays: " + why
    git("rm", "-q", "-r", os.path.join(module, "snapshot", "output"))
    git("add", "-A", module)
    return "reshaped %d case(s)" % len(order)


def main(argv):
    if not argv:
        print(__doc__)
        return 2
    cmd, rest = argv[0], argv[1:]
    botopink = os.path.abspath("zig-out/bin/botopink")
    keep = None
    paths = []
    i = 0
    while i < len(rest):
        if rest[i] == "--botopink":
            botopink = os.path.abspath(rest[i + 1])
            i += 2
        elif rest[i] == "--keep":
            keep = os.path.abspath(rest[i + 1])
            i += 2
        else:
            paths.append(rest[i])
            i += 1
    if cmd == "list":
        for m in modules():
            print(m)
        return 0
    if cmd == "try":
        code = 0
        for m in paths:
            ok, whys = plan(m, botopink, keep)
            print("%s: %d case(s) fold" % (m, len(ok)))
            for c in ok:
                print("  folds %s (%s)" % (c.name, c.kind))
            for k, v in sorted(whys.items()):
                print("  stays %s: %s" % (k, v))
            if whys:
                code = 1
        return code
    if cmd == "reshape":
        for m in paths:
            print("%s: %s" % (m, reshape(m, botopink)), flush=True)
        return 0
    if cmd == "apply":
        return max([apply(m, botopink) for m in paths] or [0])
    print(__doc__)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
