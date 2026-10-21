#!/usr/bin/env python3
"""Decision 618's migration: `Implementation.Node` is renamed `JavaScript`.

A source `.Node(…)` becomes `.JavaScript(…)` (`#[@external(.Node("$0.length"))]`
→ `#[@external(.JavaScript("$0.length"))]`), `Implementation.Node` becomes
`Implementation.JavaScript`, and a mention of the variant as code in prose —
`` `.Node` ``, `.Node` in a cell's answer (`.Node` on `biggest` …) — follows.
A name that ends in `Node` (`ast.Node`, `JsNode`), the old annotation form
`External.Node` and the word Node (the runtime) are left alone: only a `.`
with no word before it, or `Implementation.`, names the variant.

Paths are files or directories (walked for `.bp`, `.zig`, `.md`, `.sh`,
`.snap` and `.json`). `--check` writes nothing and lists what it would
rewrite; every rewritten file is printed as `path: <n> sites`.

    scripts/codemod/implementation_javascript.py libs/std conformance modules scripts
"""
import os
import re
import sys

EXTS = ('.bp', '.zig', '.md', '.sh', '.snap', '.json')

# `.Node` with no word before the dot (`.Node(`, `` `.Node` ``), and
# `Implementation.Node`.
VARIANT = re.compile(r'(?<![\w$])\.Node\b|\bImplementation\.Node\b')


def rewrite(text):
    return VARIANT.subn(lambda m: m.group(0)[:-len('Node')] + 'JavaScript', text)


def files(paths):
    for p in paths:
        if os.path.isfile(p):
            yield p
            continue
        for root, dirs, names in os.walk(p):
            dirs[:] = [d for d in dirs if not d.startswith('.') and d not in ('zig-out', 'node_modules')]
            for name in sorted(names):
                if name.endswith(EXTS):
                    yield os.path.join(root, name)


def main(argv):
    check = '--check' in argv
    paths = [a for a in argv if a != '--check']
    if not paths:
        print(__doc__.strip(), file=sys.stderr)
        return 2
    me = os.path.abspath(__file__)
    total = 0
    for path in files(paths):
        if os.path.abspath(path) == me:
            continue
        try:
            with open(path, encoding='utf-8') as f:
                text = f.read()
        except (UnicodeDecodeError, OSError):
            continue
        out, n = rewrite(text)
        if n == 0:
            continue
        total += n
        print(f'{path}: {n} sites')
        if not check:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(out)
    print(f'{total} sites', file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
