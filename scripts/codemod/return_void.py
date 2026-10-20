#!/usr/bin/env python3
"""144 B-21's codemod: decision 622 — every function writes its return type, `-> void` included.

    fn f(x: i32) { … }                ->  fn f(x: i32) -> void { … }
    pub fn main() {}                  ->  pub fn main() -> void {}
    fn m(self: Self) { … }            ->  fn m(self: Self) -> void { … }      (a method, a `default fn`, a static)
    declare fn log(s: string);        ->  declare fn log(s: string) -> void;  (a bodyless member too)
    val f = fn(x: i32) { … };         ->  val f = fn(x: i32) -> void { … };   (a `fn` expression)

Only a `fn` that writes no `->`, and only the forms 622 names: a named `fn` (free, method, `default`,
static, `declare`), with or without a body, and a `fn` expression with a body. Left as written, each
listed as `LEFT <path>:<line> <why>`:

* a function TYPE (`cb: fn(i32)`, `-> fn(i32) {`) — no function, no arrow to add;
* a marked `fn` (`async fn f() {`) — `marker-type-mismatch` already names the wrapper to write (584 (3));
* a body whose own scope writes `return <value>` — it answers a value, and the codemod does not guess its
  type (622: `-> void` *or its type*); the site is written by hand;
* a body whose own scope writes `throw` — it needs a `Result` in its return (298), written by hand;
* a lambda `{ x -> … }` — it declares no types (328), so 622 does not reach it.

    scripts/codemod/return_void.py [--check] [--zig] [--snapshots] PATH...

Without a flag it rewrites every `.bp` file under each PATH in place and prints the per-form counts;
`--zig` rewrites the `\\\\` blocks and the one-line `"…"` literals of `.zig` files; `--snapshots` moves the locations a cell's snapshot
records with the text they point into; `--check` writes nothing and exits 1 when a file would change.
"""
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compiler_keyword import mask, match_close, skip_ws, IDENT  # noqa: E402
from compiler_keyword import functions as all_functions  # noqa: E402
from prelude_names import move_snapshot_locations, SKIP_DIRS, ZIG_LINE  # noqa: E402
from body_markers import own_scope, return_operands  # noqa: E402

# A cell whose point is the missing arrow keeps it: decision 33's `bodyless-fn-needs-return-type`, and
# 622's own `fn-return-missing` cells.
SKIP_CELLS = (
    "conformance/modules/bodyless/cells/bodyless_fn_no_return_type/",
    "conformance/modules/fn_return_missing/",
    "conformance/modules/fn_return_missing_fn_expr/",
    "conformance/modules/fn_return_missing_main/",
    "conformance/modules/fn_return_missing_method/",
)
PREV_MARKER = re.compile(r"\b(async|iter|component)\s+$")
ARROW = " -> void"


class Fn:
    def __init__(self):
        self.start = 0       # the `fn` keyword
        self.name = None     # the declared name, None for a `fn` expression or a type
        self.close = 0       # the `)` closing the parameters
        self.ret = None      # True when an `->` follows
        self.body = None     # (start, end) inside the braces
        self.semi = False    # a `;` right after the parameters: a bodyless declaration


def functions(m):
    fns = []
    for mo in re.finditer(r"\bfn\b", m):
        i = skip_ws(m, mo.end())
        nm = IDENT.match(m, i)
        if nm:
            i = skip_ws(m, nm.end())
            # A qualified `implement` method: `fn UsbCharger.Connect(self: Self) { … }`.
            if i < len(m) and m[i] == ".":
                q = IDENT.match(m, skip_ws(m, i + 1))
                if q:
                    nm = q
                    i = skip_ws(m, q.end())
        if i < len(m) and m[i] == "<":
            c = match_close(m, i)
            if c < 0:
                continue
            i = skip_ws(m, c + 1)
        if i >= len(m) or m[i] != "(":
            continue
        close = match_close(m, i)
        if close < 0:
            continue
        f = Fn()
        f.start, f.close = mo.start(), close
        f.name = nm.group(0) if nm else None
        j = skip_ws(m, close + 1)
        f.ret = m.startswith("->", j)
        if not f.ret:
            if j < len(m) and m[j] == "{":
                bc = match_close(m, j)
                if bc > 0:
                    f.body = (j + 1, bc)
            f.semi = j < len(m) and m[j] == ";"
        fns.append(f)
    return fns


def untyped(m, fn):
    """`fn(x) { … }`: a parameter written without its type (408 — every parameter typed or none)."""
    o = m.rfind("(", fn.start, fn.close)
    params = [p.strip() for p in m[o + 1:fn.close].split(",") if p.strip()]
    return any(":" not in p for p in params)


def line_of(text, p):
    return text.count("\n", 0, p) + 1


def rewrite(text):
    m = mask(text)
    fns = functions(m)
    scopes = [g for g in all_functions(m) if g.body]
    edits, counts, left = [], collections.Counter(), []
    for fn in fns:
        if fn.ret:
            continue
        before = m[:fn.start].rstrip()
        if fn.name is None:
            # `fn(…)` after `->`, `:` or `<`, or with no body, is a function type.
            if fn.body is None or before.endswith(("->", ":", "<")):
                continue
            if untyped(m, fn):
                left.append((line_of(text, fn.start), "untyped fn expression (question)"))
                continue
        elif fn.body is None and not fn.semi:
            continue
        if PREV_MARKER.search(m[:fn.start]):
            left.append((line_of(text, fn.start), "marked fn without a return type"))
            continue
        if fn.body is not None:
            # Every nested function's body, arrowed or not, is a scope of its own.
            own = own_scope(m, fn, scopes)
            if any(x for x in return_operands(own)):
                left.append((line_of(text, fn.start), "returns a value: write its type"))
                continue
            # A `throw` needs a `Result` in the return (298): `-> void` would refuse it.
            if re.search(r"\bthrow\b", own):
                left.append((line_of(text, fn.start), "throws: write its Result type"))
                continue
        edits.append((fn.close + 1, fn.close + 1, ARROW))
        kind = "fn expression" if fn.name is None else ("bodyless fn" if fn.body is None else "fn")
        counts[kind] += 1
    out, at = [], 0
    for a, b, t in sorted(edits):
        out.append(text[at:a])
        out.append(t)
        at = b
    out.append(text[at:])
    return "".join(out), counts, edits, left


ZIG_STRING = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
ZIG_ESCAPES = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "'": "'", "\\": "\\"}


def decode_zig(raw):
    """A Zig string literal's bytes, and for each decoded offset the raw one it starts at."""
    out, at, k = [], [], 0
    while k < len(raw):
        at.append(k)
        if raw[k] == "\\" and k + 1 < len(raw):
            out.append(ZIG_ESCAPES.get(raw[k + 1], raw[k + 1]))
            k += 2
        else:
            out.append(raw[k])
            k += 1
    at.append(len(raw))
    return "".join(out), at


def rewrite_zig_strings(line, lineno, counts, left):
    """The one-line `"…"` literals of a Zig line that hold `.bp` source with a `fn` (a test's
    `"pub fn main() {}"`, a compiler-built `"fn main() {\\n"`): each arrow-less function gains
    `-> void` as in a `\\\\` block."""
    if "fn" not in line:
        return line
    out, at = [], 0
    for mo in ZIG_STRING.finditer(line):
        src, offsets = decode_zig(mo.group(1))
        if not re.search(r"\bfn\b", src):
            continue
        _, c, edits, lf = rewrite(src)
        counts.update(c)
        left += [(lineno, why) for _, why in lf]
        if not edits:
            continue
        base = mo.start(1)
        for a, _, t in sorted(edits):
            p = base + offsets[a]
            out.append(line[at:p])
            out.append(t)
            at = p
    out.append(line[at:])
    return "".join(out)


# The parser's and the formatter's tests assert columns on one-line sources and never reach the
# checker: their one-line literals stay as written (their `\\\\` blocks are rewritten).
ONE_LINE_SKIP = ("/src/parser/", "/src/format/")


def rewrite_zig(text, one_line=True):
    lines = text.split("\n")
    out, i, counts, left = [], 0, collections.Counter(), []
    while i < len(lines):
        if not ZIG_LINE.match(lines[i]):
            out.append(rewrite_zig_strings(lines[i], i + 1, counts, left) if one_line else lines[i])
            i += 1
            continue
        j = i
        while j < len(lines) and ZIG_LINE.match(lines[j]):
            j += 1
        block = lines[i:j]
        prefix = ZIG_LINE.match(block[0]).group(1)
        src = "\n".join(ZIG_LINE.match(ln).group(2) for ln in block)
        new, c, _, lf = rewrite(src)
        counts.update(c)
        left += [(i + ln, why) for ln, why in lf]
        out.extend([prefix + ln for ln in new.split("\n")] if new != src else block)
        i = j
    return "\n".join(out), counts, left


def files_under(paths, ext):
    for root in paths:
        if os.path.isfile(root):
            yield root
            continue
        for d, dirs, fs in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS and x != "snapshots")
            for f in sorted(fs):
                path = os.path.join(d, f)
                if f.endswith(ext) and not any(c in path.replace(os.sep, "/") for c in SKIP_CELLS):
                    yield path


def main(argv):
    check, zig, snaps = "--check" in argv, "--zig" in argv, "--snapshots" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    total, changed, moved, nleft = collections.Counter(), 0, 0, 0
    for path in files_under(paths, ".zig" if zig else ".bp"):
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if zig:
            new, counts, left = rewrite_zig(text, not any(d in path.replace(os.sep, "/") for d in ONE_LINE_SKIP))
            edits = None
        else:
            new, counts, edits, left = rewrite(text)
        for ln, why in left:
            print("LEFT %s:%d %s" % (path, ln, why))
            nleft += 1
        total.update(counts)
        if new == text:
            continue
        changed += 1
        if check:
            print("WOULD CHANGE " + path)
            continue
        if snaps and edits:
            moved += move_snapshot_locations(path, text, new, edits)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new)
    for form, n in sorted(total.items()):
        print("%6d  %s" % (n, form))
    print("%6d  files %s" % (changed, "to change" if check else "changed"))
    print("%6d  sites left" % nleft)
    if snaps:
        print("%6d  snapshot locations moved" % moved)
    return 1 if check and changed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
