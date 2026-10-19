#!/usr/bin/env python3
"""144 B-116 (ii)'s codemod: decisions 553 (2), (6) and 732 — the prelude's wrapper types are named
after their markers.

    Task      ->  Async         (`async`)
    Iterator  ->  Iter          (`iter`)
    Stream    ->  AsyncIter     (`async iter`)

`Result` and `Component` keep their names. In a `.bp` file the rename is made in code, in comments
and in `test "…"` names, never inside a string (a program's text is its answer). In `.zig`, `.md`
and `.snap`-less documents (`--text`) every word is respelled. `--snapshots` moves the `at` / `from`
locations of each rewritten cell's `snapshot/**.snap` with the text they point into, and respells the
compiler's messages those files record (`refused …`, `label …`, `stderr …` lines).

    scripts/codemod/marker_types.py [--check] [--text] [--snapshots] PATH...

Without `--text` it rewrites every `.bp` file under each PATH in place; with `--text`, every file
named on the command line or found under a PATH with one of the extensions `.zig`, `.md`.
`--check` writes nothing and exits 1 when a file would change.
"""
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compiler_keyword import mask  # noqa: E402
from prelude_names import TEST_NAME, move_snapshot_locations, SKIP_DIRS  # noqa: E402

NAMES = {"Task": "Async", "Iterator": "Iter", "Stream": "AsyncIter"}
WORD = re.compile(r"\b(Task|Iterator|Stream)\b")
# Zig files whose `Stream` is a Zig struct, not the prelude's type.
SKIP_TEXT = ("modules/std-wasm/src/random.zig", "modules/std-wasm/src/term_faces.zig", "modules/std-wasm/src/wasm.zig")


def rewrite_bp(text):
    m = mask(text)
    edits, counts = [], collections.Counter()
    starts = [0] + [i + 1 for i, c in enumerate(text) if c == "\n"]
    for ls in starts:
        le = text.find("\n", ls)
        le = len(text) if le < 0 else le
        line = text[ls:le]
        if not WORD.search(line):
            continue
        k, cut = 0, None
        while True:
            k = line.find("//", k)
            if k < 0:
                break
            if m[ls + k:ls + k + 2] == "  " and line[:k].count('"') % 2 == 0:
                cut = k
                break
            k += 2
        tn = TEST_NAME.match(line)
        for mo in WORD.finditer(line):
            a = ls + mo.start()
            in_comment = cut is not None and mo.start() >= cut
            in_test = tn is not None and tn.start(2) <= mo.start() < tn.end(2)
            in_code = m[a:a + len(mo.group())] == mo.group()
            if in_comment or in_test or in_code:
                edits.append((a, a + len(mo.group()), NAMES[mo.group()]))
                counts[mo.group() + " -> " + NAMES[mo.group()]] += 1
    out, at = [], 0
    for a, b, t in sorted(edits):
        out.append(text[at:a])
        out.append(t)
        at = b
    out.append(text[at:])
    return "".join(out), counts, edits


def rewrite_text(text):
    counts = collections.Counter()

    def sub(mo):
        counts[mo.group() + " -> " + NAMES[mo.group()]] += 1
        return NAMES[mo.group()]

    return WORD.sub(sub, text), counts


def rename_snapshot_messages(paths):
    """The compiler's messages a cell's `snapshot/**.snap` records (`refused …` and `label …` lines),
    respelled; a program's printed output is never touched."""
    n = 0
    for root in paths:
        for d, dirs, fs in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in (".botopinkbuild", "node_modules", "out"))
            if os.path.basename(d) != "snapshot" and "/snapshot/" not in d.replace(os.sep, "/") + "/":
                continue
            for f in fs:
                if not f.endswith(".snap"):
                    continue
                sp = os.path.join(d, f)
                with open(sp, encoding="utf-8") as fh:
                    lines = fh.read().split("\n")
                new = [WORD.sub(lambda mo: NAMES[mo.group()], ln) if ln.startswith(("refused ", "label ", "stderr ")) else ln for ln in lines]
                if new != lines:
                    n += 1
                    with open(sp, "w", encoding="utf-8") as fh:
                        fh.write("\n".join(new))
    return n


def files_under(paths, exts):
    for root in paths:
        if os.path.isfile(root):
            yield root
            continue
        for d, dirs, fs in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS and x != "snapshots")
            for f in sorted(fs):
                if f.endswith(exts):
                    yield os.path.join(d, f)


def main(argv):
    check, text_mode, snaps = "--check" in argv, "--text" in argv, "--snapshots" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    total, changed, moved = collections.Counter(), 0, 0
    for path in files_under(paths, (".zig", ".md") if text_mode else (".bp",)):
        norm = os.path.abspath(path).replace(os.sep, "/")
        if any(norm.endswith(s) for s in SKIP_TEXT):
            continue
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if text_mode:
            new, counts = rewrite_text(text)
            edits = None
        else:
            new, counts, edits = rewrite_bp(text)
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
        if not check:
            print("%6d  snapshots with a message respelled" % rename_snapshot_messages(paths))
    return 1 if check and changed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
