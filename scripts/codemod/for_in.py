#!/usr/bin/env python3
"""144 B-22's codemod: decision 950 — the collection loop is `for x in xs { … }`.

    for (xs) { x -> … }                 ->  for x in xs { … }
    for await (s) { x -> … }            ->  for await x in s { … }
    for :outer (0..n) { i -> … }        ->  for :outer i in 0..n { … }
    iter for (xs) { x -> yield x; }     ->  iter for x in xs { yield x; }
    for (try xs) { x -> … }             ->  for x in try xs { … }
    for (xs.map { y -> y }) { x -> … }  ->  for x in (xs.map { y -> y }) { … }   (a `{` in the iterable: kept in parentheses)

Token-safe (comments and string contents are masked, `${…}` holes read as code) and idempotent: the
new form has no `(` after `for`, so a second run finds nothing. A parenthesised `for` it cannot
rewrite — no `x ->` binder (`for-without-binder`), two binders (`for-binds-one-name`) — is listed as
`LEFT <path>:<line> <why>` and written by hand.

    scripts/codemod/for_in.py [--check | --write] [--snapshots] PATH...

Each PATH is a file or a directory walked for `.bp` / `.bpp` / `.botopink` sources, the `\\\\` blocks
and the one-line `"…"` literals of `.zig` files, the ```botopink / ```bp fences and the `…` code spans
of `.md` files (`.snap.md` included: its ```botopink source block). `--check` (the default) writes nothing, prints
each file that would change and the per-kind site counts, and exits 1 when one would; `--write`
rewrites in place. A path under SKIP, and a Zig literal, a `\\\\` block or a Markdown line that
holds a KEEP word (it names the retired form on purpose), is left as written. `--snapshots` (with
`--write`) moves the `at src/…:L:C` locations a cell's snapshot records with the text they point into.
"""
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compiler_keyword import mask, match_close, skip_ws, IDENT  # noqa: E402
from prelude_names import move_snapshot_locations, SKIP_DIRS, ZIG_LINE  # noqa: E402

FOR = re.compile(r"(?<![\w.$@])for\b")
# A text that names the old form on purpose — the refusal's own cell, a message or a sentence that says what
# 950 retired — keeps it: a file under a SKIP path, and a Zig literal, a `\\` block, a Markdown line or span
# that holds one of the KEEP words.
SKIP = ("conformance/modules/decisions-taken/for_in_loop-950/",)
KEEP = ("for-parenthesised", "forParenthesised", "950", "105's")


def kept(text):
    return any(k in text for k in KEEP)
AWAIT = re.compile(r"await\b")
LABEL = re.compile(r":[A-Za-z_][A-Za-z0-9_]*")


def line_of(text, p):
    return text.count("\n", 0, p) + 1


def rewrite(text):
    """(new text, Counter of site kinds, [(start, end, replacement)] edits, [(line, why)] left)."""
    m = mask(text)
    edits, counts, left = [], collections.Counter(), []
    for mo in FOR.finditer(m):
        j = skip_ws(m, mo.end())
        kind = "for"
        aw = AWAIT.match(m, j)
        if aw:
            kind = "for await"
            j = skip_ws(m, aw.end())
        lb = LABEL.match(m, j)
        if lb:
            j = skip_ws(m, lb.end())
        if j >= len(m) or m[j] != "(":
            continue
        close = match_close(m, j)
        if close < 0:
            continue
        k = skip_ws(m, close + 1)
        if k >= len(m) or m[k] != "{":
            continue
        p = skip_ws(m, k + 1)
        b = IDENT.match(m, p)
        q = skip_ws(m, b.end()) if b else p
        if b and m.startswith(",", q):
            left.append((line_of(text, mo.start()), "two binders (for-binds-one-name)"))
            continue
        if not b or not m.startswith("->", q):
            left.append((line_of(text, mo.start()), "no `x ->` binder (for-without-binder)"))
            continue
        a0, a1 = j + 1, close
        while a0 < a1 and m[a0].isspace():
            a0 += 1
        while a1 > a0 and m[a1 - 1].isspace():
            a1 -= 1
        iterable = text[a0:a1]
        if "{" in m[a0:a1]:
            iterable = "(" + iterable + ")"
            kind += " (iterable kept in parentheses)"
        edits.append((j, q + 2, "%s in %s {" % (b.group(0), iterable)))
        counts[kind] += 1
    out, at = [], 0
    for a, z, t in sorted(edits):
        out.append(text[at:a])
        out.append(t)
        at = z
    out.append(text[at:])
    return "".join(out), counts, edits, left


# ── `.zig` sources: the `\\` blocks and the one-line literals ───────────────

ZIG_STRING = re.compile(r'"((?:[^"\\\n]|\\.)*)"')
ZIG_DECODE = {"n": "\n", "t": "\t", "r": "\r", '"': '"', "'": "'", "\\": "\\"}
ZIG_ENCODE = {"\n": "\\n", "\t": "\\t", "\r": "\\r", '"': '\\"', "\\": "\\\\"}


def decode_zig(raw):
    """A Zig literal's bytes, or None when it holds an escape this codemod does not round-trip."""
    out, k = [], 0
    while k < len(raw):
        if raw[k] == "\\":
            if k + 1 >= len(raw) or raw[k + 1] not in ZIG_DECODE:
                return None
            out.append(ZIG_DECODE[raw[k + 1]])
            k += 2
        else:
            out.append(raw[k])
            k += 1
    return "".join(out)


def encode_zig(src):
    return "".join(ZIG_ENCODE.get(c, c) for c in src)


def rewrite_zig_strings(line, lineno, counts, left):
    if "for" not in line or kept(line):
        return line
    out, at = [], 0
    for mo in ZIG_STRING.finditer(line):
        src = decode_zig(mo.group(1))
        if src is None or not FOR.search(src) or kept(src):
            continue
        new, c, edits, lf = rewrite(src)
        left += [(lineno, why) for _, why in lf]
        if not edits:
            continue
        counts.update(c)
        out.append(line[at:mo.start(1)])
        out.append(encode_zig(new))
        at = mo.end(1)
    out.append(line[at:])
    return "".join(out)


def rewrite_zig(text):
    lines = text.split("\n")
    out, i, counts, left = [], 0, collections.Counter(), []
    while i < len(lines):
        if not ZIG_LINE.match(lines[i]):
            out.append(rewrite_zig_strings(lines[i], i + 1, counts, left))
            i += 1
            continue
        j = i
        while j < len(lines) and ZIG_LINE.match(lines[j]):
            j += 1
        block = lines[i:j]
        prefix = ZIG_LINE.match(block[0]).group(1)
        src = "\n".join(ZIG_LINE.match(ln).group(2) for ln in block)
        new, c, edits, lf = rewrite(src) if not kept(src) else (src, collections.Counter(), [], [])
        left += [(i + ln, why) for ln, why in lf]
        # A rewrite joins no lines in a `\\` block only when no site spans one: a site that does
        # is left for the hand, so the block keeps its line count.
        if edits and new.count("\n") == src.count("\n"):
            counts.update(c)
            out.extend(prefix + ln for ln in new.split("\n"))
        else:
            if edits:
                left.append((i + 1, "a site spanning lines in a \\\\ block"))
            out.extend(block)
        i = j
    return "\n".join(out), counts, left


# ── `.md`: fenced botopink blocks and inline code spans ─────────────────────

FENCE = re.compile(r"^(\s*)```(\w*)\s*$")
SPAN = re.compile(r"(`+)(.+?)\1")
BP_FENCES = ("botopink", "bp", "")


def rewrite_md(text):
    lines = text.split("\n")
    out, i, counts, left = [], 0, collections.Counter(), []
    while i < len(lines):
        fm = FENCE.match(lines[i])
        if fm:
            j = i + 1
            while j < len(lines) and not FENCE.match(lines[j]):
                j += 1
            body = lines[i + 1:j]
            out.append(lines[i])
            if fm.group(2) in BP_FENCES:
                src = "\n".join(body)
                new, c, _, lf = rewrite(src)
                counts.update(c)
                left += [(i + 1 + ln, why) for ln, why in lf]
                out.extend(new.split("\n") if body else body)
            else:
                out.extend(body)
            if j < len(lines):
                out.append(lines[j])
            i = j + 1
            continue

        def span(mo):
            new, c, _, _ = rewrite(mo.group(2))
            counts.update(c)
            return mo.group(1) + new + mo.group(1)

        out.append(SPAN.sub(span, lines[i]) if "for" in lines[i] and not kept(lines[i]) else lines[i])
        i += 1
    return "\n".join(out), counts, left


EXTS = (".bp", ".bpp", ".botopink", ".zig", ".md")


def files_under(paths):
    for root in paths:
        if os.path.isfile(root):
            yield root
            continue
        for d, dirs, fs in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
            for f in sorted(fs):
                path = os.path.join(d, f)
                if f.endswith(EXTS) and not any(x in path.replace(os.sep, "/") for x in SKIP):
                    yield path


def main(argv):
    write, snaps = "--write" in argv, "--snapshots" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    total, changed, moved, nleft = collections.Counter(), 0, 0, 0
    for path in files_under(paths):
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if "for" not in text:
            continue
        edits = None
        if path.endswith(".zig"):
            new, counts, left = rewrite_zig(text)
        elif path.endswith(".md"):
            new, counts, left = rewrite_md(text)
        else:
            new, counts, edits, left = rewrite(text)
        for ln, why in left:
            print("LEFT %s:%d %s" % (path, ln, why))
            nleft += 1
        if new == text:
            continue
        total.update(counts)
        changed += 1
        if not write:
            print("WOULD CHANGE %s (%d)" % (path, sum(counts.values())))
            continue
        if snaps and edits:
            moved += move_snapshot_locations(path, text, new, edits)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new)
    for form, n in sorted(total.items()):
        print("%6d  %s" % (n, form))
    print("%6d  sites" % sum(total.values()))
    print("%6d  files %s" % (changed, "changed" if write else "to change"))
    print("%6d  sites left" % nleft)
    if snaps:
        print("%6d  snapshot locations moved" % moved)
    return 1 if not write and changed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
