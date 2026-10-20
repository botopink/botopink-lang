#!/usr/bin/env python3
"""144 B-116 P2's codemod: decisions 553 (1), 570 — a body that compiles specially carries its marker.

    fn f() -> Async<T> { … }          ->  async fn f() -> Async<T> { … }
    fn f() -> Iter<T> { … yield … }   ->  iter fn f() -> Iter<T> { … yield … }
    fn f() -> AsyncIter<T> { … }      ->  async iter fn f() -> AsyncIter<T> { … }
    fn F() -> Component<R> { … }      ->  component fn F() -> Component<R> { … }

Only a `fn` with a body, whose written return type is the wrapper, and that carries no marker yet:

* `Async<T>` — marked when its own scope (a nested `async { }` block, lambda or `fn` body is a scope of its
  own) writes `await`, has no `return`, or returns something that cannot be an `Async` value (a literal, an
  operator, a template). A body whose every `return` hands on a call or a name is left as written: it may be
  the unmarked function 570 keeps (`return Async.resolve(v)`, a value already of the type); the P4 refusal
  names any this guess leaves behind.
* `Iter<T>` / `AsyncIter<T>` — marked when its own scope writes `yield` (a body that does not is a factory,
  553 (5), and stays unmarked); `AsyncIter<T>` also when it writes `await`.
* `Component<R>` — marked, as every body that is not a bare factory compiles specially (570).

    scripts/codemod/body_markers.py [--check] [--zig] [--snapshots] PATH...

Without a flag it rewrites every `.bp` file under each PATH in place and prints the per-rule counts;
`--zig` rewrites the `\\\\` blocks of `.zig` tests; `--snapshots` moves the locations a cell's snapshot
records with the text they point into; `--check` writes nothing and exits 1 when a file would change.
"""
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compiler_keyword import mask, match_close, functions  # noqa: E402
from prelude_names import move_snapshot_locations, SKIP_DIRS, ZIG_LINE  # noqa: E402

HEAD = re.compile(r"\s*(AsyncIter|Async|Iter|Component)\s*<")
PREV_MARKER = re.compile(r"\b(async|iter|component)\s+$")
WORD = lambda w: re.compile(r"\b%s\b" % w)  # noqa: E731


def blank(chars, a, b):
    for k in range(a, b):
        if chars[k] != "\n":
            chars[k] = " "


def loop_body(m, a, p):
    """Whether the `{` at `p` opens a `for (…) { x -> … }` body: its binding list is no lambda, and the
    body is the function's own scope."""
    j = p - 1
    while j >= a and m[j].isspace():
        j -= 1
    if j < a or m[j] != ")":
        return False
    depth = 0
    while j >= a:
        if m[j] == ")":
            depth += 1
        elif m[j] == "(":
            depth -= 1
            if depth == 0:
                break
        j -= 1
    # `iter for (…) { … }` / `stream for` is a generator scope of its own (decision 125).
    return re.search(r"\bfor\s*$", m[a:j]) is not None and re.search(r"\b(iter|stream)\s+for\s*$", m[a:j]) is None


def own_scope(m, fn, fns):
    """The body of `fn` with every nested scope (a `fn` body, an `async { }` block, a lambda, an
    `iter loop { }`) blanked."""
    a, b = fn.body
    chars = list(m)
    for g in fns:
        if g is not fn and g.body and a <= g.start and g.body[1] <= b:
            blank(chars, g.start, g.body[1] + 1)
    for mo in re.finditer(r"\{", m[a:b]):
        p = a + mo.start()
        if chars[p] == " ":
            continue
        prev = "".join(chars[a:p]).rstrip()
        nested = re.search(r"\b(async|iter|stream)\s*(loop)?$", prev) is not None and (
            prev.endswith("async") or prev.endswith("loop"))
        if not nested and not loop_body(m, a, p):
            nested = re.match(r"\s*(?:(?:async|iter|component)\s+)*(?:[A-Za-z_]\w*(?:\s*,\s*[A-Za-z_]\w*)*)?\s*->",
                              "".join(chars[p + 1:b])) is not None
        if nested:
            c = match_close(m, p)
            if c > 0:
                blank(chars, p, c + 1)
    return "".join(chars[a:b])


def return_operands(own):
    out = []
    for mo in re.finditer(r"\breturn\b", own):
        depth, j = 0, mo.end()
        while j < len(own):
            c = own[j]
            if c in "([{<" and not (c == "<" and own[j - 1:j + 1] == " <" and False):
                depth += 1
            elif c in ")]}>":
                depth -= 1
            elif c == ";" and depth <= 0:
                break
            j += 1
        out.append(own[mo.end():j].strip())
    return out


PASS_THROUGH = re.compile(r"^[A-Za-z_][\w.]*(\s*\(.*\))?$", re.S)


def marker_for(m, fn, fns):
    if not fn.body or fn.ret is None:
        return None
    r = HEAD.match(m, fn.ret[0])
    if not r:
        return None
    before = m[:fn.start].rstrip()
    if PREV_MARKER.search(m[:fn.start]):
        return None
    # An anonymous `fn(…) -> T` after `->`, `:` or `<` is a function TYPE (`-> fn(n: i32) -> Async<i32> {`
    # is a method whose return type is one), never a function expression.
    if fn.name is None and before.endswith(("->", ":", "<")):
        return None
    own = own_scope(m, fn, fns)
    has = {w: WORD(w).search(own) is not None for w in ("await", "yield")}
    head = r.group(1)
    if head == "Async":
        rets = return_operands(own)
        if has["await"] or not rets or any(not PASS_THROUGH.match(x) for x in rets):
            return "async "
    elif head == "Iter":
        if has["yield"]:
            return "iter "
    elif head == "AsyncIter":
        if has["yield"] or has["await"]:
            return "async iter "
    elif head == "Component":
        return "component "
    return None


def rewrite(text):
    m = mask(text)
    fns = functions(m)
    edits, counts = [], collections.Counter()
    for fn in fns:
        mk = marker_for(m, fn, fns)
        if mk:
            edits.append((fn.start, fn.start, mk))
            counts[mk.strip() + " fn"] += 1
    out, at = [], 0
    for a, b, t in sorted(edits):
        out.append(text[at:a])
        out.append(t)
        at = b
    out.append(text[at:])
    return "".join(out), counts, edits


def rewrite_zig(text):
    lines = text.split("\n")
    out, i, counts = [], 0, collections.Counter()
    while i < len(lines):
        if not ZIG_LINE.match(lines[i]):
            out.append(lines[i])
            i += 1
            continue
        j = i
        while j < len(lines) and ZIG_LINE.match(lines[j]):
            j += 1
        block = lines[i:j]
        prefix = ZIG_LINE.match(block[0]).group(1)
        src = "\n".join(ZIG_LINE.match(ln).group(2) for ln in block)
        new, c, _ = rewrite(src)
        counts.update(c)
        out.extend([prefix + ln for ln in new.split("\n")] if new != src else block)
        i = j
    return "\n".join(out), counts


def files_under(paths, ext):
    for root in paths:
        if os.path.isfile(root):
            yield root
            continue
        for d, dirs, fs in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS and x != "snapshots")
            for f in sorted(fs):
                if f.endswith(ext):
                    yield os.path.join(d, f)


def main(argv):
    check, zig, snaps = "--check" in argv, "--zig" in argv, "--snapshots" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    total, changed, moved = collections.Counter(), 0, 0
    for path in files_under(paths, ".zig" if zig else ".bp"):
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if zig:
            new, counts = rewrite_zig(text)
            edits = None
        else:
            new, counts, edits = rewrite(text)
        total.update(counts)
        if new == text:
            continue
        changed += 1
        if check:
            print("WOULD CHANGE " + path)
            continue
        if snaps and edits is not None:
            moved += move_snapshot_locations(path, text, new, edits)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new)
    for rule, n in sorted(total.items()):
        print("%6d  %s" % (n, rule))
    print("%6d  files %s" % (changed, "to change" if check else "changed"))
    if snaps:
        print("%6d  snapshot locations moved" % moved)
    return 1 if check and changed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
