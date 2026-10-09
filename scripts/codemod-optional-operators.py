#!/usr/bin/env python3
"""Decision 330 codemod: `?T` is read with TypeScript's operators and has no
methods; the builtin `result` namespace goes.

    name.unwrapOr("anon")          ->  name ?? "anon"            (on a `?T`)
    xs.at(0).unwrapOr(a + b)       ->  xs.at(0) ?? (a + b)
    !flag.unwrapOr(false)          ->  !(flag ?? false)
    result.map(r, f)               ->  r.map(f)
    result.then(r, f)              ->  r.flatMap(f)
    result.unwrap(r, 0)            ->  r.unwrapOr(0)               (a `@Result` keeps it)
    result.isOk(parse(s))          ->  parse(s).isOk()

Which `.unwrapOr` reads a `?T` is the compiler's answer, never a guess: the
script runs `botopink check` in every project under each ROOT (a directory
holding a `botopink.json`; a workspace's members are projects of their own) and
rewrites the sites the compiler names — `optional-has-no-methods` on
`unwrapOr`, located at the method's name. A `@Result`'s `.unwrapOr` is left
alone. It repeats until the compiler names no site it can rewrite (the
compiler reports one error per module per run). The `result.<op>(…)` calls
are rewritten textually first: no other receiver spells `result.then`,
`result.unwrap`, `result.isOk` or `result.isError`, and `result.map` is taken
only with two arguments (a local array's `map` takes one).

An optional operator over a value the compiler says is never null (a narrowed
name, a plain type) is dropped — `a ?? b` is `a`, `a?.f` is `a.f`, `a!` is
`a` — which is what it evaluated to. A `.map` / `.flatMap` on a `?T` whose
lambda only projects its parameter (`x.map({ v -> v.name })`) becomes `x?.name`.
A site it cannot rewrite — any other `.map` / `.flatMap` or method on a `?T`,
`??` beside `&&` / `||` — is printed as `UNDECIDED <file>:<line>:<col> <what>` and left for a
person; the run exits 1 when there is one.

    scripts/codemod-optional-operators.py [--write] [--once] [--compiler BOTOPINK] ROOT...

`--once` stops after one compiler pass — for std, whose sources are embedded in
the compiler, so its sites move only when the compiler is rebuilt. Without
`--write` it reports the `result.<op>` rewrites only (the compiler
loop needs the files written to converge). Afterwards the formatter is run
over every file it changed that was canonical before (`--compiler`'s
`format --check`), so `botopink format --check` stays green and a file it was
not canonical for keeps its layout.

The compiler's report is read in two shapes: its diagnostics (`error: <code>:
…` then ` --> <file>:<line>:<col>`) and, from a build that reports every site
in one run, `CODEMOD\\t<code>\\t<file>\\t<line>\\t<col>\\t<detail>` lines.
"""
import json
import os
import re
import subprocess
import sys

SKIP_DIRS = {".botopinkbuild", "node_modules", "out", "zig-out", ".zig-cache", ".git"}
SOURCE_EXTS = (".bp", ".bp.fixture")

# ── the textual `result.<op>(…)` rewrite ────────────────────────────────────

RESULT_OPS = {"map": "map", "then": "flatMap", "unwrap": "unwrapOr", "isOk": "isOk", "isError": "isError"}
RESULT_CALL = re.compile(r"(?<![\w.])result\.(map|then|unwrap|isOk|isError)\(")


def match_close(text, open_idx):
    """Index of the bracket closing the one at `open_idx`, skipping strings."""
    pairs = {"(": ")", "[": "]", "{": "}"}
    stack = [pairs[text[open_idx]]]
    i = open_idx + 1
    while i < len(text):
        c = text[i]
        if c == '"':
            if text.startswith('"""', i):
                end = text.find('"""', i + 3)
                i = (end + 3) if end >= 0 else len(text)
                continue
            i += 1
            while i < len(text) and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c == "/" and text.startswith("//", i):
            nl = text.find("\n", i)
            i = nl if nl >= 0 else len(text)
            continue
        elif c in pairs:
            stack.append(pairs[c])
        elif c in ")]}":
            if not stack or stack[-1] != c:
                return -1
            stack.pop()
            if not stack:
                return i
        i += 1
    return -1


def split_args(text):
    """Top-level comma-separated arguments of an argument list's inside."""
    args, depth, start, i = [], 0, 0, 0
    while i < len(text):
        c = text[i]
        if c == '"':
            i += 1
            while i < len(text) and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif c == "," and depth == 0:
            args.append(text[start:i])
            start = i + 1
        i += 1
    tail = text[start:]
    if tail.strip():
        args.append(tail)
    return [a.strip() for a in args]


def is_postfix_operand(expr):
    """True when `expr` is a primary with a postfix chain — safe as a receiver."""
    return top_level_operator(expr) is None and not expr.startswith(("-", "!", "try ", "await ", "if ", "{"))


def top_level_operator(expr):
    depth, i = 0, 0
    while i < len(expr):
        c = expr[i]
        if c == '"':
            i += 1
            while i < len(expr) and expr[i] != '"':
                i += 2 if expr[i] == "\\" else 1
        elif c in "([{":
            depth += 1
        elif c in ")]}":
            depth -= 1
        elif depth == 0:
            if c in "+*/%<>=&|^":
                return c
            if c == "-" and i > 0:
                return c
            if c == "?" and expr.startswith("??", i):
                return "??"
            if expr.startswith(" is ", i) or expr.startswith(" as ", i):
                return "is"
        i += 1
    return None


def rewrite_result_calls(text):
    out, pos, count = [], 0, 0
    for m in RESULT_CALL.finditer(text):
        if m.start() < pos:
            continue
        line_start = text.rfind("\n", 0, m.start()) + 1
        if text[line_start:m.start()].lstrip().startswith("//"):
            continue  # prose, not code
        open_idx = m.end() - 1
        close = match_close(text, open_idx)
        if close < 0:
            continue
        args = split_args(text[open_idx + 1:close])
        op = m.group(1)
        if not args or (op == "map" and len(args) != 2):
            continue
        recv = args[0] if is_postfix_operand(args[0]) else "(" + args[0] + ")"
        rest = ", ".join(args[1:])
        out.append(text[pos:m.start()])
        out.append("%s.%s(%s)" % (recv, RESULT_OPS[op], rest))
        pos = close + 1
        count += 1
    out.append(text[pos:])
    return "".join(out), count


# ── the compiler-located `.unwrapOr(d)` → `?? d` rewrite ───────────────────

IDENT_CHARS = re.compile(r"[\w@]")


def receiver_start(text, dot):
    """Start of the postfix chain that ends just before `dot` (the `.` of
    `.unwrapOr`)."""
    i = dot
    while True:
        j = i - 1
        # A chain broken over lines: whitespace before a `.` / `?.` link.
        k = j
        while k >= 0 and text[k] in " \t\r\n":
            k -= 1
        if k < j and text[i] == ".":
            j = k
        if j < 0:
            return 0
        c = text[j]
        if c in ")]}":
            open_char = {")": "(", "]": "[", "}": "{"}[c]
            depth, m = 0, j
            while m >= 0:
                if text[m] == '"' and m != j:
                    # a string inside the group: its brackets are text
                    m -= 1
                    while m >= 0 and not (text[m] == '"' and (m == 0 or text[m - 1] != "\\")):
                        m -= 1
                elif text[m] == c:
                    depth += 1
                elif text[m] == open_char:
                    depth -= 1
                    if depth == 0:
                        break
                m -= 1
            i = m
            # a call / index: its callee or receiver comes before
            continue
        if c == '"':
            m = j - 1
            while m >= 0 and not (text[m] == '"' and text[m - 1] != "\\"):
                m -= 1
            i = m
            continue
        if IDENT_CHARS.match(c):
            m = j
            while m >= 0 and IDENT_CHARS.match(text[m]):
                m -= 1
            i = m + 1
            continue
        if c == "." or c == "!":
            if c == "!" and j + 1 < len(text) and text[j + 1] == "=":
                return i
            if c == "!" and (j == 0 or not (IDENT_CHARS.match(text[j - 1]) or text[j - 1] in ')]"')):
                return i  # a prefix `!` — not part of the chain
            i = j
            if c == "." and j > 0 and text[j - 1] == "?":
                i = j - 1
            continue
        if c == "#" and i < len(text) and text[i] == "(":
            i = j
            continue
        return i


def line_col_to_offset(text, line, col):
    """The string offset of a compiler location: the column counts bytes."""
    off = 0
    for _ in range(line - 1):
        off = text.index("\n", off) + 1
    end = text.find("\n", off)
    row = text[off:end if end >= 0 else len(text)]
    return off + len(row.encode("utf-8")[:col - 1].decode("utf-8", "ignore"))


def rewrite_unwrap_or(text, line, col):
    """`<recv>.unwrapOr(<d>)` with `unwrapOr` at line:col → `<recv> ?? <d>`."""
    name = line_col_to_offset(text, line, col)
    if not text.startswith("unwrapOr(", name):
        return None
    dot = name - 1
    if text[dot] != ".":
        return None
    if dot > 0 and text[dot - 1] == "?":
        return None  # `x?.unwrapOr(d)` — not this rewrite
    open_idx = name + len("unwrapOr")
    close = match_close(text, open_idx)
    if close < 0:
        return None
    args = split_args(text[open_idx + 1:close])
    if len(args) != 1:
        return None
    default = args[0]
    start = receiver_start(text, dot)
    recv = text[start:dot].rstrip()
    if top_level_operator(default) is not None or default.startswith(("if ", "try ", "await ", "{")):
        default = "(" + default + ")"
    expr = "%s ?? %s" % (recv, default)
    before = text[:start].rstrip(" \t")
    after = text[close + 1:]
    wrap = False
    if before.endswith(("!", "-")) and not before.endswith(("!=", "->")):
        wrap = True
    if before.endswith(("&&", "||")) or after.lstrip(" \t").startswith(("&&", "||")):
        wrap = True
    if after.startswith((".", "?.", "[", "(", "!")) and not after.startswith("!="):
        wrap = True
    # A broken chain continuing on the next line.
    if re.match(r"\s*\n\s*\??\.", after):
        wrap = True
    if wrap:
        expr = "(" + expr + ")"
    return text[:start] + expr + text[close + 1:]


PROJECTION = re.compile(r"^\{\s*(\w+)\s*->\s*\1((?:\.\w+(?:\([^{}\n]*\))?)+)\s*;?\s*\}$")


def rewrite_map_projection(text, line, col):
    """`x.map({ v -> v.f })` (or `flatMap`) on a `?T` with `map` at line:col →
    `x?.f`: a projection through the optional is `?.`, which flattens."""
    name = line_col_to_offset(text, line, col)
    m = re.match(r"(map|flatMap)\(", text[name:])
    if not m or text[name - 1] != "." or text[name - 2] == "?":
        return None
    open_idx = name + m.end() - 1
    close = match_close(text, open_idx)
    if close < 0:
        return None
    args = split_args(text[open_idx + 1:close])
    if len(args) != 1:
        return None
    pm = PROJECTION.match(args[0])
    if not pm:
        return None
    # every link reads through the optional: `x?.entry?.pattern`
    links = re.findall(r"\.\w+(?:\([^{}\n]*\))?", pm.group(2))
    return text[:name - 1] + "".join("?" + l for l in links) + text[close + 1:]


def primary_end(text, i):
    """End (exclusive) of the operand `??` takes at `i`: a primary with its
    postfix chain — a chain broken over lines included — and a further `??`."""
    n = len(text)
    while i < n and text[i] in " \t":
        i += 1
    while i < n and text[i] in "-!":
        i += 1
    if i >= n:
        return i
    c = text[i]
    if c == '"':
        if text.startswith('"""', i):
            i = text.find('"""', i + 3) + 3
        else:
            i += 1
            while i < n and text[i] != '"':
                i += 2 if text[i] == "\\" else 1
            i += 1
    elif c in "([{":
        i = match_close(text, i) + 1
    elif c == "#" and i + 1 < n and text[i + 1] == "(":
        i = match_close(text, i + 1) + 1
    else:
        while i < n and (IDENT_CHARS.match(text[i]) or (text[i] == "." and i + 1 < n and text[i + 1].isdigit())):
            i += 1
    while i < n:
        m = re.match(r"(\s*\n\s*)?(\?\.|\.)", text[i:])
        if m and (m.group(1) is None or True):
            j = i + m.end()
            if j < n and text[j] in "[(":
                i = match_close(text, j) + 1
                continue
            k = j
            while k < n and IDENT_CHARS.match(text[k]):
                k += 1
            if k == j:
                break
            i = k
            continue
        if text[i] in "([":
            i = match_close(text, i) + 1
            continue
        if text[i] == "!" and not text.startswith("!=", i):
            i += 1
            continue
        break
    m = re.match(r"\s*\?\?", text[i:])
    if m:
        return primary_end(text, i + m.end())
    return i


def rewrite_never_null(text, line, col, op):
    """Drop an optional operator over a value that is never null: `a ?? b` is
    `a`, `a?.f` is `a.f`, `a?.[i]` is `a[i]`, `f?.(x)` is `f(x)`, `a!` is `a`."""
    off = line_col_to_offset(text, line, col)
    if op == "??" and text.startswith("??", off):
        start = off
        while start > 0 and text[start - 1] in " \t":
            start -= 1
        end = primary_end(text, off + 2)
        new = text[:start] + text[end:]
        # `(maxAge ?? 0).toString()` → `maxAge.toString()`
        m = re.search(r"(?<![\w.)\]])\((\w+)$", new[:start])
        if m and new[start:start + 1] == ")":
            new = new[:start - len(m.group(0))] + m.group(1) + new[start + 1:]
        return new
    if op in ("?.[]", "?.()") and text.startswith("?.", off):
        return text[:off] + text[off + 2:]
    if op == "?." and text[off - 2:off] == "?.":
        return text[:off - 2] + "." + text[off:]
    if op == "!" and text.startswith("!", off):
        return text[:off] + text[off + 1:]
    return None


# ── projects and the compiler loop ──────────────────────────────────────────

def find_projects(root):
    projects = []
    for d, dirs, files in os.walk(root):
        dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
        if "botopink.json" in files:
            try:
                with open(os.path.join(d, "botopink.json"), encoding="utf-8") as f:
                    manifest = json.load(f)
            except (OSError, ValueError):
                continue
            if "workspaces" in manifest and not os.path.isdir(os.path.join(d, "src")):
                continue
            projects.append(d)
    return projects


def source_files(root):
    for d, dirs, files in os.walk(root):
        dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
        for f in sorted(files):
            if f.endswith(SOURCE_EXTS):
                yield os.path.join(d, f)


DIAG = re.compile(r"^error(?:\[[\w-]+\])?: (.*)$")
LOC = re.compile(r"^\s*--> (.+?):(\d+):(\d+)\s*$")
ANSI = re.compile(r"\x1b\[[0-9;]*m")


def compiler_sites(compiler, project):
    """(code, file, line, col, detail) the compiler names in `project`."""
    proc = subprocess.run([compiler, "check"], cwd=project, capture_output=True, text=True)
    lines = [ANSI.sub("", l) for l in (proc.stdout + proc.stderr).splitlines()]
    sites = []
    for idx, l in enumerate(lines):
        if l.startswith("CODEMOD\t"):
            _, code, path, line, col, detail = l.split("\t", 5)
            sites.append((code, path, int(line), int(col), detail))
            continue
        m = DIAG.match(l)
        if not m:
            continue
        msg = m.group(1)
        for nxt in lines[idx + 1: idx + 4]:
            lm = LOC.match(nxt)
            if lm:
                code = msg.split(":", 1)[0]
                detail = ""
                dm = re.search(r"unknown method `(\w+)`", msg)
                if dm:
                    detail = dm.group(1)
                om = re.search(r"`([^`]+)` over a value that is never null", msg)
                if om:
                    detail = om.group(1)
                sites.append((code, lm.group(1), int(lm.group(2)), int(lm.group(3)), detail))
                break
    return sites


def resolve_path(project, path):
    if os.path.isabs(path):
        return os.path.realpath(path)
    cand = os.path.join(project, path)
    if os.path.exists(cand):
        return os.path.realpath(cand)
    # `libs/std/src/x.bp` from a build that reports std's own sites.
    here = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    cand = os.path.join(here, path)
    return os.path.realpath(cand) if os.path.exists(cand) else None


def is_canonical(compiler, path):
    """True when `botopink format --check` leaves `path` as it is."""
    if not compiler:
        return False
    proc = subprocess.run([compiler, "format", "--check", path], capture_output=True, text=True)
    return proc.returncode == 0


def main(argv):
    write = "--write" in argv
    once = "--once" in argv
    compiler = None
    roots = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a in ("--write", "--once"):
            pass
        elif a == "--compiler":
            i += 1
            compiler = argv[i]
        elif a.startswith("--compiler="):
            compiler = a.split("=", 1)[1]
        else:
            roots.append(a)
        i += 1
    if not roots:
        print(__doc__)
        return 2
    changed = set()
    canonical = {}  # path -> whether the formatter left it alone before any rewrite
    undecided = {}
    tally = {"result": 0, "unwrapOr": 0, "neverNull": 0, "projection": 0}

    for root in roots:
        for path in source_files(root):
            with open(path, encoding="utf-8") as f:
                text = f.read()
            new, n = rewrite_result_calls(text)
            if n:
                tally["result"] += n
                print("result.<op> x%d  %s" % (n, path))
                if write:
                    canonical.setdefault(os.path.abspath(path), is_canonical(compiler, path))
                    with open(path, "w", encoding="utf-8") as f:
                        f.write(new)
                    changed.add(os.path.abspath(path))

    if write and compiler:
        projects = []
        for root in roots:
            projects.extend(find_projects(root))
        for _ in range(64):
            undecided = {}
            by_file = {}
            for project in projects:
                for code, path, line, col, detail in compiler_sites(compiler, project):
                    full = resolve_path(project, path)
                    key = (full or path, line, col)
                    if code == "optional-has-no-methods" and detail == "unwrapOr" and full:
                        by_file.setdefault(full, set()).add((line, col, "unwrapOr"))
                    elif code == "optional-operator-never-null" and full:
                        by_file.setdefault(full, set()).add((line, col, detail))
                    elif code == "optional-has-no-methods" and detail in ("map", "flatMap") and full:
                        by_file.setdefault(full, set()).add((line, col, detail))
                    elif code in ("optional-has-no-methods", "nullish-beside-logical"):
                        undecided[key] = "%s %s" % (code, detail)
            progressed = False
            for full, sites in sorted(by_file.items()):
                canonical.setdefault(os.path.abspath(full), is_canonical(compiler, full))
                with open(full, encoding="utf-8") as f:
                    text = f.read()
                # Last site first: a rewrite never moves a site before it.
                for line, col, what in sorted(sites, reverse=True):
                    if what == "unwrapOr":
                        new = rewrite_unwrap_or(text, line, col)
                    elif what in ("map", "flatMap"):
                        new = rewrite_map_projection(text, line, col)
                    else:
                        new = rewrite_never_null(text, line, col, what)
                    if new is None or new == text:
                        undecided[(full, line, col)] = "%s not rewritten" % what
                        continue
                    text = new
                    kind = {"unwrapOr": "unwrapOr", "map": "projection", "flatMap": "projection"}.get(what, "neverNull")
                    tally[kind] += 1
                    progressed = True
                    print("%s %s  %s:%d:%d" % (kind, what, full, line, col))
                with open(full, "w", encoding="utf-8") as f:
                    f.write(text)
                changed.add(os.path.abspath(full))
            if not progressed or once:
                break

    # Only a file the formatter left alone before is formatted after: one it
    # would have reformatted keeps its layout, and the diff is the rewrite.
    if compiler and changed:
        for path in sorted(changed):
            if canonical.get(path):
                subprocess.run([compiler, "format", path], capture_output=True, text=True)
    for (path, line, col), what in sorted(undecided.items()):
        print("UNDECIDED %s:%d:%d %s" % (path, line, col, what))
    print("tally: %d result.<op> rewritten, %d .unwrapOr -> ??, %d .map projections -> ?., %d never-null operators dropped, %d files changed, %d undecided"
          % (tally["result"], tally["unwrapOr"], tally["projection"], tally["neverNull"], len(changed), len(undecided)))
    return 1 if undecided else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
