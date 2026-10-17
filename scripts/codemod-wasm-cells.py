#!/usr/bin/env python3
"""Decision 481's migration: `@External.Wasm`'s prefixed strings become labelled cells.

    #[@External.Wasm("fn:tanBody")]            -> #[@External.Wasm(fn: tanBody)]
    #[@External.Wasm("op:f64.floor")]          -> #[@External.Wasm(op: "f64.floor")]
    #[@External.Wasm("wasi:race_of")]          -> #[@External.Wasm(wasi: .RaceOf)]
    #[@External.Wasm("std:hash.contentHash")]  -> #[@External.Wasm(std: "hash.contentHash")]

Usage: python3 scripts/codemod-wasm-cells.py [--write] [--ext <.ext>]... <root>...

Textual, over code and comments alike (`@External.Wasm("fn:…")` in prose becomes
`@External.Wasm(fn: …)`). It reads `.bp`, `.d.bp` and `.bp.fixture` files, plus each
`--ext`. Prints one line per file it changes with the count, then the tally per root;
without `--write` it only reports.
"""

import os
import re
import sys

CELL = re.compile(r'(External\.Wasm\()"(fn|op|wasi|std):([^"]*)"')
SKIP_DIRS = {".git", ".zig-cache", "zig-out", ".botopinkbuild", "node_modules", ".tasks"}


def pascal(snake):
    return "".join(part[:1].upper() + part[1:] for part in snake.split("_"))


def labelled(m):
    head, label, value = m.group(1), m.group(2), m.group(3)
    if label == "fn":
        return f"{head}fn: {value}"
    if label == "wasi":
        if re.fullmatch(r"[a-z][a-z0-9_]*", value):
            return f"{head}wasi: .{pascal(value)}"
        if value.startswith("<") and value.endswith(">"):
            return f"{head}wasi: .<Adapter>"
        return f"{head}wasi: .{value}"
    return f'{head}{label}: "{value}"'


def main(argv):
    write = False
    exts = [".bp", ".d.bp", ".bp.fixture"]
    roots = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--write":
            write = True
        elif a == "--ext":
            i += 1
            exts.append(argv[i])
        else:
            roots.append(a)
        i += 1
    if not roots:
        print(__doc__, file=sys.stderr)
        return 2
    total = 0
    for root in roots:
        n_root = 0
        walk = [(os.path.dirname(root), [], [os.path.basename(root)])] if os.path.isfile(root) else os.walk(root)
        for dirpath, dirnames, filenames in walk:
            dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
            for fn in sorted(filenames):
                if not any(fn.endswith(e) for e in exts) or fn == "CHANGELOG.md":
                    continue
                path = os.path.join(dirpath, fn)
                try:
                    text = open(path, encoding="utf-8").read()
                except (UnicodeDecodeError, OSError):
                    continue
                new, n = CELL.subn(labelled, text)
                if n == 0:
                    continue
                n_root += n
                print(f"rewrite {path}: {n}")
                if write:
                    with open(path, "w", encoding="utf-8") as out:
                        out.write(new)
        print(f"{root}: {n_root} cell(s){'' if write else ' (dry run)'}")
        total += n_root
    print(f"total: {total}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
