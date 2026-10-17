#!/usr/bin/env python3
"""codemod-conformance-cells.py — `tests/language/` into `conformance/` (144 B-29 step H,
decisions 457, 466, 475).

Every `run/`, `reject/` and `modules/` cell of the old suite becomes one directory in
decision 457 / 475's shape:

    conformance/modules/<cell>/botopink.json
    conformance/modules/<cell>/src/<module>.bp
    conformance/modules/<cell>/snapshot/output/<module>.snap
    conformance/modules/<cell>/snapshot/targets/<target>/<module>.snap   (only where a target departs)
    conformance/modules/<cell>/docs.md                                  (empty: step I writes it)

and the `test/` suites (`test/<n>.bp`, and a `modules/<n>/` project with a `test/` tree and
no `expected.out`) keep `botopink test --json` under `conformance/test/`.

Three subcommands, each rerunnable over the same two trees:

    migrate --from <old tests/language> --to <conformance>
        writes the new tree. Every claim of a sidecar that the `.snap` format can spell
        from the sidecar alone is written exactly: `.out` / `expected.out` (`out`,
        `no-final-newline`), `.exit` (`abort`), `<t>.stderr` (`stderr`), `.targets` /
        a manifest's `"targets"` (the cell's manifest `"targets"`). A refusal claim
        (`reject/<n>.expect`, `<n>.<t>.expect`, `modules/<n>/<t>.expect`) names a part
        of the compiler's message, and a `.snap` holds the whole `error…` line: it is
        written as a placeholder (`refused <the claimed text>` / `at <the claimed
        place>`), which `botopink cell check` answers with a candidate holding the
        compiler's whole line.

    accept --from <old tests/language> --to <conformance>
        after `botopink cell check <conformance>/modules` wrote its candidates: each
        candidate is checked against the old claims of every target that reads it
        (a refusal claim: some `refused` line contains the claimed text and its `at`
        is the claimed place, and the target prints nothing; an output claim: the
        candidate is never accepted — a changed output is a red, named for a person).
        A candidate every claim backs is renamed over its `.snap`; any other is
        listed and left. Then identical departures of every declared target fold
        into `output/`, and a departure equal to `output/` is deleted.

    audit --from <old tree> --to <conformance> [--cells <file>]
        every claim of the old tree, counted by kind, and each one checked against
        the new tree's snapshots (the answer a target reads: `targets/<t>/<m>.snap`,
        else `output/<m>.snap`, else empty). Prints the counts before and after and
        exits 1 when one claim has no record that states it. `--cells` writes the
        cell-by-cell ledger.

The old tree is a directory: `git archive <rev> tests/language | tar -x -C <dir>` makes one
from any revision that still holds it.
"""
import argparse
import json
import os
import re
import shutil
import sys

ALL_TARGETS = ["commonJS", "erlang", "beam", "wasm"]
HEADER = "botopink-cell 1"
# The single-file cells whose source spells the package's erlang atom in a host
# template (`'language_tests@main@@Point'`): their manifest keeps the name the
# template spells, so the program and its answer stay byte for byte the same.
KEEPS_PACKAGE_NAME = {"external_host_record", "external_method_local"}
# `reject/smoke` and `run/smoke` were two cells of one name in two kinds.
RENAMED = {("reject", "smoke"): "smoke_refused"}


# ── the .snap format (cell_snap.zig's, the subset this script writes) ────────

def render(snap):
    out = [HEADER]
    for msg, at in snap.get("refusals", []):
        out.append("refused " + msg)
        if at is not None:
            out.append("at " + at)
    stdout = snap.get("stdout", "")
    if stdout:
        ends = stdout.endswith("\n")
        body = stdout[:-1] if ends else stdout
        for line in body.split("\n"):
            out.append("out" if line == "" else "out " + line)
        if not ends:
            out.append("no-final-newline")
    if snap.get("abort"):
        out.append("abort")
    for s in snap.get("stderr", []):
        out.append("stderr " + s)
    return "\n".join(out) + "\n"


def parse(text):
    """The records of a `.snap` (no validation beyond what this script needs)."""
    snap = {"refusals": [], "stdout": "", "abort": False, "stderr": []}
    lines = text[:-1].split("\n") if text.endswith("\n") else text.split("\n")
    out = []
    nfn = False
    for line in lines[1:]:
        word, _, rest = line.partition(" ")
        if word == "refused":
            snap["refusals"].append([rest, None])
        elif word == "at":
            snap["refusals"][-1][1] = rest
        elif word == "out":
            out.append(rest)
        elif word == "no-final-newline":
            nfn = True
        elif word == "abort":
            snap["abort"] = True
        elif word == "stderr":
            snap["stderr"].append(rest)
    if out:
        snap["stdout"] = "\n".join(out) + ("" if nfn else "\n")
    return snap


def module_of(at):
    """`src/shapes/circle.bp:3:7` → `shapes/circle` (cell.zig's `moduleOf`)."""
    path = at
    for _ in range(2):
        c = path.rfind(":")
        if c >= 0 and path[c + 1:].isdigit():
            path = path[:c]
    if path.startswith("src/"):
        path = path[len("src/"):]
    if path.endswith(".bp"):
        path = path[:-len(".bp")]
    return path


# ── the old tree's claims ─────────────────────────────────────────────────────

def read(path, binary=False):
    with open(path, "rb" if binary else "r", encoding=None if binary else "utf-8") as f:
        return f.read()


def write(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "wb" if isinstance(data, bytes) else "w", encoding=None if isinstance(data, bytes) else "utf-8") as f:
        f.write(data)


def expect_claim(path, loc_of):
    lines = read(path).split("\n")
    msg = lines[0]
    loc = lines[1].strip() if len(lines) > 1 and lines[1].strip() else None
    return {"msg": msg, "at": loc_of(loc) if loc else None}


def is_test_project(d):
    return os.path.isdir(os.path.join(d, "test")) and not os.path.isfile(os.path.join(d, "expected.out"))


def old_cells(old):
    """Every cell of the old tree with its claims: one dict per cell."""
    cells = []
    for f in sorted(os.listdir(os.path.join(old, "run"))):
        if not f.endswith(".bp"):
            continue
        n = f[:-3]
        base = os.path.join(old, "run", n)
        c = {"kind": "run", "old": "run/" + f, "name": RENAMED.get(("run", n), n), "claims": []}
        declared = list(ALL_TARGETS)
        if os.path.isfile(base + ".targets"):
            declared = read(base + ".targets").split()
            c["claims"].append({"kind": "targets", "targets": declared})
        c["declared"] = [t for t in ALL_TARGETS if t in declared]
        for t in ALL_TARGETS:
            if os.path.isfile(base + "." + t + ".expect"):
                cl = expect_claim(base + "." + t + ".expect", lambda l: "src/main.bp:" + l)
                c["claims"].append(dict(cl, kind="expect", target=t))
        if os.path.isfile(base + ".out"):
            c["claims"].append({"kind": "out", "stdout": read(base + ".out", True).decode("utf-8")})
        if os.path.isfile(base + ".exit"):
            assert read(base + ".exit").strip() == "nonzero", base
            c["claims"].append({"kind": "exit"})
        for t in ALL_TARGETS:
            if os.path.isfile(base + "." + t + ".stderr"):
                c["claims"].append({"kind": "stderr", "target": t, "text": read(base + "." + t + ".stderr").split("\n")[0]})
        cells.append(c)
    for f in sorted(os.listdir(os.path.join(old, "reject"))):
        if not f.endswith(".bp"):
            continue
        n = f[:-3]
        c = {"kind": "reject", "old": "reject/" + f, "name": RENAMED.get(("reject", n), n), "declared": list(ALL_TARGETS), "claims": []}
        cl = expect_claim(os.path.join(old, "reject", n + ".expect"), lambda l: "src/main.bp:" + l)
        assert cl["at"], "reject cell without a location: " + n
        c["claims"].append(dict(cl, kind="reject"))
        cells.append(c)
    for n in sorted(os.listdir(os.path.join(old, "modules"))):
        d = os.path.join(old, "modules", n)
        if not os.path.isdir(d) or is_test_project(d):
            continue
        c = {"kind": "modules", "old": "modules/" + n, "name": n, "claims": []}
        manifest = json.loads(read(os.path.join(d, "botopink.json")))
        declared = list(ALL_TARGETS)
        if "targets" in manifest:
            declared = manifest["targets"]
            c["claims"].append({"kind": "targets", "targets": declared})
        c["declared"] = [t for t in ALL_TARGETS if t in declared]
        for t in ALL_TARGETS:
            p = os.path.join(d, t + ".expect")
            if os.path.isfile(p):
                c["claims"].append(dict(expect_claim(p, lambda l: l), kind="expect", target=t))
        if os.path.isfile(os.path.join(d, "expected.out")):
            c["claims"].append({"kind": "out", "stdout": read(os.path.join(d, "expected.out"), True).decode("utf-8")})
        cells.append(c)
    names = [c["name"] for c in cells]
    dup = sorted({n for n in names if names.count(n) > 1})
    assert not dup, "two cells of one name: " + ", ".join(dup)
    return cells


def old_suites(old):
    """The `test/` suites: `test/<n>.bp`, and the test-kind `modules/<n>/` projects."""
    suites = []
    for f in sorted(os.listdir(os.path.join(old, "test"))):
        if f.endswith(".bp"):
            suites.append(("test/" + f, f))
    for n in sorted(os.listdir(os.path.join(old, "modules"))):
        d = os.path.join(old, "modules", n)
        if os.path.isdir(d) and is_test_project(d):
            suites.append(("modules/" + n, n))
    return suites


# ── what each declared target must answer, per module ────────────────────────

def intended(c):
    """{module: {target: snap}} — the answer the old claims give each declared
    target (a refusal as its placeholder), every module a claim names."""
    claims = c["claims"]
    out = next((x for x in claims if x["kind"] == "out"), None)
    aborts = any(x["kind"] == "exit" for x in claims)
    stderr = {x["target"]: x["text"] for x in claims if x["kind"] == "stderr"}
    refusals = {}
    for x in claims:
        if x["kind"] == "expect":
            refusals[x["target"]] = x
        elif x["kind"] == "reject":
            for t in c["declared"]:
                refusals[t] = x
    answers = {"main": {}}
    for t in c["declared"]:
        if t in refusals:
            x = refusals[t]
            m = module_of(x["at"]) if x["at"] else "main"
            answers.setdefault(m, {})[t] = {"refusals": [[x["msg"], x["at"]]]}
            if m != "main":
                answers["main"][t] = {}
        else:
            snap = {"stdout": out["stdout"] if out else "", "abort": aborts}
            if t in stderr:
                snap["stderr"] = [stderr[t]]
            answers["main"][t] = snap
    return answers


def place(declared, by_target):
    """Split one module's per-target answers into `output/` and departures: the
    answer most targets give is `output/` (a tie goes to the one that is not a
    refusal), the others depart. Returns (output text or None, {target: text})."""
    texts = {t: render(s) for t, s in by_target.items()}
    readers = [t for t in declared if t in texts]
    counts = {}
    for t in readers:
        counts[texts[t]] = counts.get(texts[t], 0) + 1
    if not counts:
        return None, {}
    best = sorted(counts, key=lambda k: (-counts[k], "\nrefused " in k, k))[0]
    # A target the module answers nothing on reads an empty answer.
    empty = render({})
    missing = [t for t in declared if t not in texts]
    if missing and best != empty and counts[best] <= len(missing):
        best = empty
    output = None if best == empty else best
    departures = {t: texts.get(t, empty) for t in declared if texts.get(t, empty) != best}
    return output, departures


def snapshot_paths(cell_dir, m, output, departures):
    files = {}
    if output is not None:
        files[os.path.join(cell_dir, "snapshot", "output", m + ".snap")] = output
    for t, text in departures.items():
        files[os.path.join(cell_dir, "snapshot", "targets", t, m + ".snap")] = text
    return files


# ── migrate ───────────────────────────────────────────────────────────────────

def copy_tree(src, dst, skip_top=()):
    for name in sorted(os.listdir(src)):
        if name in skip_top:
            continue
        s, d = os.path.join(src, name), os.path.join(dst, name)
        if os.path.isdir(s):
            shutil.copytree(s, d, symlinks=True)
        else:
            os.makedirs(dst, exist_ok=True)
            shutil.copy2(s, d)


def manifest_text(name, targets):
    m = '{ "name": "%s", "version": "0.0.1", "src": "src/"' % name
    if targets is not None:
        m += ', "targets": [%s]' % ", ".join('"%s"' % t for t in targets)
    return m + " }\n"


def migrate(old, new):
    mods = os.path.join(new, "modules")
    tests = os.path.join(new, "test")
    for d in (mods, tests):
        if os.path.exists(d):
            shutil.rmtree(d)
    for c in old_cells(old):
        cell = os.path.join(mods, c["name"])
        if c["kind"] in ("run", "reject"):
            write(os.path.join(cell, "src", "main.bp"), read(os.path.join(old, c["old"]), True))
            targets = next((x["targets"] for x in c["claims"] if x["kind"] == "targets"), None)
            name = "language_tests" if c["name"] in KEEPS_PACKAGE_NAME else c["name"]
            write(os.path.join(cell, "botopink.json"), manifest_text(name, targets))
        else:
            src = os.path.join(old, c["old"])
            skip = {"expected.out"} | {t + ".expect" for t in ALL_TARGETS}
            copy_tree(src, cell, skip)
        write(os.path.join(cell, "docs.md"), "")
        for m, by_target in sorted(intended(c).items()):
            output, departures = place(c["declared"], by_target)
            for p, text in snapshot_paths(cell, m, output, departures).items():
                write(p, text)
    for old_path, name in old_suites(old):
        src = os.path.join(old, old_path)
        if os.path.isdir(src):
            shutil.copytree(src, os.path.join(tests, name), symlinks=True)
        else:
            write(os.path.join(tests, name), read(src, True))
    print("migrate: %d cells into %s, %d test suites into %s" % (len(old_cells(old)), mods, len(old_suites(old)), tests))


# ── the answer a target reads ─────────────────────────────────────────────────

def snaps_of(cell_dir, sub, new_too=False):
    """{module: text} under snapshot/<sub>/ (`.snap`, or `.snap.new` over it)."""
    root = os.path.join(cell_dir, "snapshot", sub)
    found = {}
    if not os.path.isdir(root):
        return found
    for dp, _, fs in os.walk(root):
        for f in fs:
            rel = os.path.relpath(os.path.join(dp, f), root)
            if f.endswith(".snap"):
                found.setdefault(rel[:-5], read(os.path.join(dp, f)))
    if new_too:
        for dp, _, fs in os.walk(root):
            for f in fs:
                rel = os.path.relpath(os.path.join(dp, f), root)
                if f.endswith(".snap.new"):
                    found[rel[:-9]] = read(os.path.join(dp, f))
    return found


def effective(cell_dir, declared, new_too=False):
    """{target: {module: snap}} — what each declared target reads."""
    output = snaps_of(cell_dir, "output", new_too)
    eff = {}
    for t in declared:
        own = snaps_of(cell_dir, os.path.join("targets", t), new_too)
        mods = dict(output)
        mods.update(own)
        eff[t] = {m: parse(text) for m, text in mods.items()}
    return eff


def check_claims(c, eff):
    """Each claim of the cell against what the targets read: a list of
    (claim kind, target or '*', ok, why)."""
    results = []
    claims = c["claims"]
    refusing = set()
    for x in claims:
        if x["kind"] == "expect":
            refusing.add(x["target"])
        elif x["kind"] == "reject":
            refusing.update(c["declared"])
    for x in claims:
        k = x["kind"]
        if k == "targets":
            results.append((k, "*", None, None))  # checked on the manifest
        elif k in ("expect", "reject"):
            ts = [x["target"]] if k == "expect" else c["declared"]
            for t in ts:
                mods = eff[t]
                hit = any(x["msg"] in msg and (x["at"] is None or at == x["at"])
                          for s in mods.values() for msg, at in s["refusals"])
                prints = any(s["stdout"] or s["abort"] for s in mods.values())
                why = None if hit and not prints else (
                    "no `refused` line contains %r%s" % (x["msg"], " at " + x["at"] if x["at"] else "") if not hit
                    else "the target refuses and still prints")
                results.append((k, t, why is None, why))
        elif k == "out":
            for t in c["declared"]:
                if t in refusing:
                    continue
                main = eff[t].get("main", parse(HEADER + "\n"))
                ok = main["stdout"] == x["stdout"] and not main["refusals"]
                results.append((k, t, ok, None if ok else "main's output is not the .out"))
        elif k == "exit":
            for t in c["declared"]:
                if t in refusing:
                    continue
                main = eff[t].get("main", parse(HEADER + "\n"))
                results.append((k, t, main["abort"], None if main["abort"] else "main does not abort"))
        elif k == "stderr":
            t = x["target"]
            main = eff[t].get("main", parse(HEADER + "\n"))
            ok = x["text"] in main["stderr"] and main["abort"]
            results.append((k, t, ok, None if ok else "no `stderr %s` record" % x["text"]))
    return results


# ── accept ────────────────────────────────────────────────────────────────────

def candidates_of(cell_dir):
    found = []
    for dp, _, fs in os.walk(os.path.join(cell_dir, "snapshot")):
        for f in fs:
            if f.endswith(".snap.new"):
                found.append(os.path.join(dp, f))
    return sorted(found)


def accept(old, new):
    mods = os.path.join(new, "modules")
    left = []
    accepted = 0
    for c in old_cells(old):
        cell = os.path.join(mods, c["name"])
        cands = candidates_of(cell)
        if not cands:
            fold(cell, c["declared"])
            continue
        # A changed output or abort is never accepted here: it is a red (or an
        # answer that names the package) for a person to read.
        out_claims = [x for x in c["claims"] if x["kind"] in ("out", "exit", "stderr")]
        eff = effective(cell, c["declared"], new_too=True)
        results = check_claims(c, eff)
        bad = [r for r in results if r[2] is False]
        touches_output = False
        for p in cands:
            snap = parse(read(p))
            if snap["stdout"] or snap["abort"]:
                touches_output = True
        if bad or (touches_output and out_claims):
            left.append((c, cands, bad))
            continue
        for p in cands:
            os.replace(p, p[: -len(".new")])
            accepted += 1
        fold(cell, c["declared"])
    for c, cands, bad in left:
        print("LEFT %s (%s)" % (c["name"], c["old"]))
        for p in cands:
            print("  candidate %s" % os.path.relpath(p, new))
        for k, t, _, why in bad:
            print("  %s [%s]: %s" % (k, t, why))
    print("accept: %d candidates accepted, %d cells left for a person" % (accepted, len(left)))
    return 1 if left else 0


def fold(cell, declared):
    """Departures every declared target shares move to `output/`; a departure
    equal to what `output/` says (or an empty one where `output/` has no file)
    is deleted."""
    tdir = os.path.join(cell, "snapshot", "targets")
    if not os.path.isdir(tdir):
        return
    output = snaps_of(cell, "output")
    per = {t: snaps_of(cell, os.path.join("targets", t)) for t in declared}
    modules = set()
    for d in per.values():
        modules.update(d)
    empty = HEADER + "\n"
    for m in sorted(modules):
        texts = [per[t].get(m) for t in declared]
        if all(x is not None for x in texts) and len(set(texts)) == 1:
            text = texts[0]
            out_path = os.path.join(cell, "snapshot", "output", m + ".snap")
            if text == empty:
                if os.path.exists(out_path):
                    os.remove(out_path)
            else:
                write(out_path, text)
            for t in declared:
                os.remove(os.path.join(tdir, t, m + ".snap"))
            output = snaps_of(cell, "output")
            continue
        for t in declared:
            text = per[t].get(m)
            if text is not None and text == output.get(m, empty):
                os.remove(os.path.join(tdir, t, m + ".snap"))
    for dp, ds, fs in sorted(os.walk(tdir, topdown=False)):
        if not os.listdir(dp):
            os.rmdir(dp)


# ── audit ─────────────────────────────────────────────────────────────────────

def audit(old, new, cells_file):
    mods = os.path.join(new, "modules")
    before = {}
    after = {}
    ledger = []
    failed = 0
    files_before = {"run .out": 0, "run .exit": 0, "run <t>.expect": 0, "run <t>.stderr": 0, "run .targets": 0,
                    "reject .expect": 0, "modules expected.out": 0, "modules <t>.expect": 0, "modules \"targets\"": 0}
    for c in old_cells(old):
        kind = c["kind"]
        for x in c["claims"]:
            key = {("run", "out"): "run .out", ("run", "exit"): "run .exit", ("run", "expect"): "run <t>.expect",
                   ("run", "stderr"): "run <t>.stderr", ("run", "targets"): "run .targets",
                   ("reject", "reject"): "reject .expect", ("modules", "out"): "modules expected.out",
                   ("modules", "expect"): "modules <t>.expect", ("modules", "targets"): "modules \"targets\""}[(kind, x["kind"])]
            files_before[key] += 1
        cell = os.path.join(mods, c["name"])
        eff = effective(cell, c["declared"])
        results = check_claims(c, eff)
        manifest = json.loads(read(os.path.join(cell, "botopink.json")))
        for k, t, ok, why in results:
            if k == "targets":
                want = next(x["targets"] for x in c["claims"] if x["kind"] == "targets")
                ok = manifest.get("targets") == want
                why = None if ok else "the manifest's \"targets\" is not the old narrowing"
            before[k] = before.get(k, 0) + 1
            if ok:
                after[k] = after.get(k, 0) + 1
            else:
                failed += 1
            ledger.append("%s\t%s\t%s\t%s\t%s" % (c["old"], c["name"], k, t, "ok" if ok else "LOST: " + why))
        if "targets" in manifest and not any(x["kind"] == "targets" for x in c["claims"]):
            failed += 1
            ledger.append("%s\t%s\ttargets\t*\tLOST: a narrowing the old cell did not make" % (c["old"], c["name"]))
    suites = old_suites(old)
    for old_path, name in suites:
        a = os.path.join(old, old_path)
        b = os.path.join(new, "test", name)
        same = same_tree(a, b)
        before["test suite"] = before.get("test suite", 0) + 1
        if same:
            after["test suite"] = after.get("test suite", 0) + 1
        else:
            failed += 1
        ledger.append("%s\t%s\ttest suite\t*\t%s" % (old_path, "test/" + name, "ok" if same else "LOST: not the same bytes"))
    print("files before (one claim each, a reject .expect one per target it binds):")
    for k, v in files_before.items():
        print("  %-22s %d" % (k, v))
    print("claims checked, per target (before → after):")
    for k in sorted(before):
        print("  %-10s %5d → %5d" % (k, before[k], after.get(k, 0)))
    if cells_file:
        write(cells_file, "\n".join(ledger) + "\n")
    print("audit: %s" % ("every claim stated by a record of the new tree" if failed == 0 else "%d claims LOST" % failed))
    return 1 if failed else 0


def same_tree(a, b):
    if os.path.isfile(a):
        return os.path.isfile(b) and read(a, True) == read(b, True)
    if not os.path.isdir(b):
        return False
    la = sorted(os.listdir(a))
    lb = sorted(os.listdir(b))
    if la != lb:
        return False
    return all(same_tree(os.path.join(a, n), os.path.join(b, n)) for n in la)


def main():
    p = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    p.add_argument("command", choices=["migrate", "accept", "audit"])
    p.add_argument("--from", dest="old", required=True)
    p.add_argument("--to", dest="new", required=True)
    p.add_argument("--cells")
    a = p.parse_args()
    if a.command == "migrate":
        migrate(a.old, a.new)
        return 0
    if a.command == "accept":
        return accept(a.old, a.new)
    return audit(a.old, a.new, a.cells)


if __name__ == "__main__":
    sys.exit(main())
