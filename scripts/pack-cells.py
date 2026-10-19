#!/usr/bin/env python3
"""Pack a module's cases into two packages (decision 779).

A module of `conformance/modules/` (a directory holding `cases/<case>/`, decision 765)
becomes:

    <module>/docs.md
    <module>/run/       one package: every case that prints, called in order by src/main.bp
    <module>/refused/   one package: every case the compiler refuses, one .snap per case module
    <module>/cells/<case>/   a full cell, unchanged, for a case that cannot share a package

A case joins `run/` or `refused/` only when the packaged answer is proved equal to its
old one: the candidate package is checked with `botopink cell check` on every target
against the old answers (run/: the cases' `out` lines concatenated in call order;
refused/: each case's old `.snap` with its `at`/`from` path moved under
`src/cases/<case>/`). A candidate that fails is split in halves until each failing case
is alone, and that case goes to `cells/` unchanged.

    pack-cells.py apply [--botopink <bin>] <module>...   pack these modules in place; a run/ or
                                                          refused/ already there is kept and the new
                                                          cases are merged into it
    pack-cells.py list                                    the modules still holding cases/
"""

import json
import os
import re
import shutil
import subprocess
import sys
import tempfile

HEADER = "botopink-cell 1"
PLAIN_ENTRIES = {"botopink.json", "src", "snapshot", "docs.md"}
MAIN_RE = re.compile(r"^pub fn main\(\) \{", re.M)
IDENT_RE = re.compile(r"^[a-z_][a-z0-9_]*$")
ENTRY = "runCase"  # a case's entry; never `main` (it recurses on wasm) nor a name a case uses
CHECK_TIMEOUT = 900


def read(p):
    with open(p, encoding="utf-8") as f:
        return f.read()


def write(p, text):
    os.makedirs(os.path.dirname(p), exist_ok=True)
    with open(p, "w", encoding="utf-8") as f:
        f.write(text)


def snaps(case):
    """{module path: text} of a case's accepted output answers."""
    out = os.path.join(case, "snapshot", "output")
    found = {}
    for dp, _, fs in os.walk(out):
        for f in fs:
            if f.endswith(".snap"):
                rel = os.path.relpath(os.path.join(dp, f), out)
                found[rel[: -len(".snap")]] = read(os.path.join(dp, f))
    return found


def code_lines(text):
    return [l for l in text.splitlines() if not l.lstrip().startswith("//")]


def own_modules(case):
    """The case's own top-level module names, besides main."""
    src = os.path.join(case, "src")
    names = []
    for e in os.listdir(src):
        if e == "main.bp":
            continue
        if os.path.isdir(os.path.join(src, e)):
            names.append(e)
        elif e.endswith(".bp"):
            names.append(e[:-3])
    return names


def spell(name):
    return name if IDENT_RE.match(name) else "`" + name + "`"


def rewrite_imports(text, case_name, own):
    """`import {shapes.x}` names the package root; under src/cases/<case>/ it is
    `import {cases.<case>.shapes.x}`. Imports with `from` are untouched."""
    if not own:
        return text
    spellings = sorted({"`" + n + "`" for n in own} | {n for n in own if IDENT_RE.match(n)}, key=len, reverse=True)
    alt = "|".join(re.escape(s) for s in spellings)
    item = re.compile(r"(^|[{,]\s*)(" + alt + r")(?=[.\s,}]|$)")
    prefix = "cases." + spell(case_name) + "."
    out, i = [], 0
    for m in re.finditer(r"import\s*\{", text):
        start = m.end()
        depth, j = 1, start
        while j < len(text) and depth:
            depth += {"{": 1, "}": -1}.get(text[j], 0)
            j += 1
        if re.match(r"\s*from\b", text[j:]):
            continue
        body = text[start : j - 1]
        out.append(text[i:start])
        out.append(item.sub(lambda mm: mm.group(1) + prefix + mm.group(2), body))
        i = j - 1
    out.append(text[i:])
    return "".join(out)


def classify(case):
    """'run', 'refused' or None (a full cell)."""
    if set(os.listdir(case)) - PLAIN_ENTRIES:
        return None
    if json.loads(read(os.path.join(case, "botopink.json"))).keys() - {"name"}:
        return None
    if os.path.isdir(os.path.join(case, "snapshot", "targets")):
        return None
    answers = snaps(case)
    if not answers:
        return None
    if any(l.startswith("refused ") for t in answers.values() for l in t.splitlines()):
        if any("at botopink.json" in t for t in answers.values()):
            return None
        return "refused"
    if list(answers) != ["main"]:
        return None
    lines = answers["main"].splitlines()
    if any(not (l.startswith("out ") or l == "out") for l in lines[1:]):
        return None  # abort, stderr, no-final-newline
    main = read(os.path.join(case, "src", "main.bp"))
    if len(MAIN_RE.findall(main)) != 1:
        return None
    if sum(len(re.findall(r"\bmain\b", l)) for l in code_lines(main)) != 1:
        return None
    if any(re.search(r"\b" + ENTRY + r"\b", read(os.path.join(dp, f))) for dp, _, fs in os.walk(os.path.join(case, "src")) for f in fs):
        return None
    return "run"


def lay_case(case, dest, kind):
    """Copy a case's sources to `dest` (src/cases/<case>/), main.bp as mod.bp."""
    name = os.path.basename(case)
    own = own_modules(case)
    src = os.path.join(case, "src")
    for dp, _, fs in os.walk(src):
        for f in fs:
            rel = os.path.relpath(os.path.join(dp, f), src)
            text = read(os.path.join(dp, f))
            if f.endswith(".bp"):
                text = rewrite_imports(text, name, own)
            if rel == "main.bp":
                rel = "mod.bp"
                if kind == "run":
                    text = MAIN_RE.sub("pub fn " + ENTRY + "() {", text, count=1)
            write(os.path.join(dest, rel), text)
    if os.path.isfile(os.path.join(case, "docs.md")):
        shutil.copy(os.path.join(case, "docs.md"), os.path.join(dest, "docs.md"))


def moved_snap(text, name):
    def mv(m):
        rest = m.group(2)
        rest = "mod.bp" if rest == "main.bp" else rest
        return m.group(1) + "src/cases/" + name + "/" + rest
    return re.sub(r"^((?:at|from) )src/([^:]+)", mv, text, flags=re.M)


def build(pkg_dir, pkg_name, kind, cases, base=None):
    """Write the package for `cases` (paths of old cells) into `pkg_dir`. With `base`, the
    package already there (its directory) is kept whole and `cases` are added to it: their
    modules and calls after its own, their answers after its answers."""
    keep = None
    if base:
        keep = tempfile.mkdtemp(prefix="pack-cells-base-")
        shutil.rmtree(keep)
        shutil.copytree(base, keep)
    shutil.rmtree(pkg_dir, ignore_errors=True)
    names = [os.path.basename(c) for c in cases]
    if keep:
        shutil.copytree(keep, pkg_dir)
        shutil.rmtree(keep)
        with open(os.path.join(pkg_dir, "src", "cases", "mod.bp"), "a", encoding="utf-8") as f:
            f.write("".join("pub mod %s;\n" % spell(n) for n in names))
        if kind == "run":
            mp = os.path.join(pkg_dir, "src", "main.bp")
            main = read(mp)
            calls = "".join("    cases.%s.%s();\n" % (spell(n), ENTRY) for n in names)
            i = main.rindex("}")
            write(mp, main[:i] + calls + main[i:])
            sp = os.path.join(pkg_dir, "snapshot", "output", "main.snap")
            lines = read(sp).splitlines()
            for c in cases:
                lines += snaps(c)["main"].splitlines()[1:]
            write(sp, "\n".join(lines) + "\n")
        else:
            for c in cases:
                n = os.path.basename(c)
                for mod, text in snaps(c).items():
                    rel = "mod" if mod == "main" else mod
                    write(os.path.join(pkg_dir, "snapshot", "output", "cases", n, rel + ".snap"), moved_snap(text, n))
    else:
        write(os.path.join(pkg_dir, "botopink.json"), json.dumps({"name": pkg_name}) .replace('{"', '{ "').replace('"}', '" }') + "\n")
        write(os.path.join(pkg_dir, "src", "cases", "mod.bp"), "".join("pub mod %s;\n" % spell(n) for n in names))
        if kind == "run":
            calls = "".join("    cases.%s.%s();\n" % (spell(n), ENTRY) for n in names)
            write(os.path.join(pkg_dir, "src", "main.bp"), "mod cases;\n\npub fn main() {\n" + calls + "}\n")
            lines = [HEADER]
            for c in cases:
                lines += snaps(c)["main"].splitlines()[1:]
            write(os.path.join(pkg_dir, "snapshot", "output", "main.snap"), "\n".join(lines) + "\n")
        else:
            write(os.path.join(pkg_dir, "src", "main.bp"), "mod cases;\n\npub fn main() {}\n")
            for c in cases:
                n = os.path.basename(c)
                for mod, text in snaps(c).items():
                    rel = "mod" if mod == "main" else mod
                    write(os.path.join(pkg_dir, "snapshot", "output", "cases", n, rel + ".snap"), moved_snap(text, n))
    for c in cases:
        lay_case(c, os.path.join(pkg_dir, "src", "cases", os.path.basename(c)), kind)


def check(botopink, pkg_dir):
    """`cell check` of the candidate; one that runs past CHECK_TIMEOUT fails, its whole
    process group killed (a runaway case must not take the machine's memory)."""
    cap = ["systemd-run", "--user", "--scope", "-q", "-p", "MemoryMax=4G", "-p", "MemorySwapMax=0"] if shutil.which("systemd-run") else []
    p = subprocess.Popen(cap + [botopink, "cell", "check", pkg_dir], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
    try:
        return p.wait(timeout=CHECK_TIMEOUT) == 0
    except subprocess.TimeoutExpired:
        os.killpg(p.pid, 9)
        p.wait()
        return False


def fit(botopink, scratch, pkg_name, kind, cases, base=None):
    """The cases that pack together, and the ones that must stay full cells."""
    if not cases:
        return [], []
    d = os.path.join(scratch, kind)
    build(d, pkg_name, kind, cases, base)
    if check(botopink, d):
        return cases, []
    if len(cases) == 1:
        return [], cases
    half = len(cases) // 2
    a_ok, a_bad = fit(botopink, scratch, pkg_name, kind, cases[:half], base)
    b_ok, b_bad = fit(botopink, scratch, pkg_name, kind, cases[half:], base)
    ok, bad = a_ok + b_ok, a_bad + b_bad
    if ok:
        build(d, pkg_name, kind, ok, base)
        if not check(botopink, d):  # two halves that check alone but not together: keep the larger
            keep = a_ok if len(a_ok) >= len(b_ok) else b_ok
            return keep, bad + [c for c in ok if c not in keep]
    return ok, bad


def apply(botopink, module):
    module = os.path.abspath(module)
    cases_dir = os.path.join(module, "cases")
    cases = sorted(os.path.join(cases_dir, n) for n in os.listdir(cases_dir) if os.path.isdir(os.path.join(cases_dir, n)))
    base = os.path.basename(module)
    kinds = {"run": [], "refused": []}
    alone = []
    for c in cases:
        k = classify(c)
        (kinds[k] if k else alone).append(c)
    placed = {}
    with tempfile.TemporaryDirectory(prefix="pack-cells-") as scratch:
        for kind, members in kinds.items():
            # a package already there (it holds earlier cases) is kept: the new cases are merged into it
            have = os.path.join(module, kind)
            have = have if os.path.isfile(os.path.join(have, "botopink.json")) else None
            if have:  # the scratch candidate starts from a copy, so a failed one leaves the package alone
                keep = os.path.join(scratch, kind + "-have")
                shutil.copytree(have, keep)
                have = keep
            name = json.loads(read(os.path.join(have, "botopink.json")))["name"] if have else base + "-" + kind
            ok, bad = fit(botopink, scratch, name, kind, members, have)
            if len(ok) == 1 and not have:  # a package of one case gains nothing over its cell
                bad, ok = bad + ok, []
            alone += bad
            placed[kind] = ok
            if ok:
                build(os.path.join(module, kind), name, kind, ok, have)
    # Moves: the packed cases' old cells go, the rest move whole to cells/.
    # Moves (plain file operations; `git add -A` records them): the packed cases' old
    # cells go, the rest move whole to cells/.
    for ok in placed.values():
        for c in ok:
            shutil.rmtree(c)
    for c in sorted(alone):
        os.makedirs(os.path.join(module, "cells"), exist_ok=True)
        os.rename(c, os.path.join(module, "cells", os.path.basename(c)))
    if os.path.isdir(cases_dir) and not os.listdir(cases_dir):
        os.rmdir(cases_dir)
    rewrite_module_docs(module, placed, alone)
    return {k: len(v) for k, v in placed.items()} | {"cells": len(alone)}


def rewrite_module_docs(module, placed, alone):
    where = {}
    for kind, ok in placed.items():
        for c in ok:
            n = os.path.basename(c)
            where[n] = "%s/src/cases/%s/mod.bp" % (kind, n)
    for c in alone:
        n = os.path.basename(c)
        where[n] = "cells/%s/src/main.bp" % n
    p = os.path.join(module, "docs.md")
    text = read(p)

    def link(m):
        n = m.group(1)
        return "[%s](%s)" % (where[n], where[n]) if n in where else m.group(0)

    write(p, re.sub(r"\[cases/([^/\]]+)/src/main\.bp\]\(cases/[^/)]+/src/main\.bp\)", link, text))


def main():
    args = sys.argv[1:]
    botopink = "botopink"
    if args[:1] == ["--botopink"] or (len(args) > 1 and args[1] == "--botopink"):
        i = args.index("--botopink")
        botopink = os.path.abspath(args[i + 1])
        del args[i : i + 2]
    if not args or args[0] not in ("apply", "list"):
        sys.exit(__doc__)
    if args[0] == "list":
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "conformance", "modules")
        for dp, dns, _ in os.walk(root):
            # a module's packages and cells hold no module (a module may be named `run`, so a package is told by its manifest)
            dns[:] = [d for d in dns if d not in ("cells", "src", "snapshot", "deps")
                      and not (d in ("run", "refused") and os.path.isfile(os.path.join(dp, d, "botopink.json")))]
            if "cases" in dns:
                print(os.path.relpath(dp, root))
                dns[:] = []
        return
    total = {"run": 0, "refused": 0, "cells": 0}
    for m in args[1:]:
        r = apply(botopink, m)
        print("%s  run %d · refused %d · cells %d" % (m, r["run"], r["refused"], r["cells"]), flush=True)
        for k in total:
            total[k] += r[k]
    print("total  run %d · refused %d · cells %d" % (total["run"], total["refused"], total["cells"]))


if __name__ == "__main__":
    main()
