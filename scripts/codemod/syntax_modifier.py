#!/usr/bin/env python3
"""Decision 616's migration: the parameter modifier `expr` is renamed `syntax`.

`expr decl: unknown` becomes `syntax decl: unknown`, `expr ..xs: T[]` becomes
`syntax ..xs: T[]` — the modifier is the word before a parameter's name (or a
variadic's `..`) and its `:`. In prose (comments, a document, a message) the
word written as code follows it: `` `expr` `` becomes `` `syntax` `` (and
`` `expr decl` `` `` `syntax decl` ``), an
`` `expr x: T` `` / `-> expr T` mention likewise, and the article before it
agrees (`an `expr`` → `a `syntax``). `@expr`, `expr-templates` and an
ordinary name `expr` are left alone. In a `.zig` file only the modifier is
rewritten (its `` `expr` `` mentions are mostly the Zig name).

Paths are files or directories (walked for `.bp`, `.zig`, `.md`, `.sh` and
`.snap`). `--check` writes nothing and lists what it would rewrite; every
rewritten file is printed as `path: <n> sites`.

    scripts/codemod/syntax_modifier.py libs/std conformance modules
"""
import os
import re
import sys

EXTS = ('.bp', '.zig', '.md', '.sh', '.snap')

# The modifier: `expr` before a parameter's name (or `..`) and its `:`.
MODIFIER = re.compile(r'(?<![\w@.$-])expr(?=[ \t]+(?:\.\.)?[A-Za-z_]\w*[ \t]*:(?!:))')
# The word as code in prose: `expr`.
TICKED = re.compile(r'`expr(?=`| \.?\.?[A-Za-z_]\w*`)')
# A return written `-> expr T` (prose: the form decision 578 removed).
RETURN = re.compile(r'-> expr(?=[ \t]+[A-Za-z_@(])')
# The article before a renamed mention.
ARTICLE = re.compile(r'\b([Aa])n (`(?:-> )?syntax\b)')


def rewrite(text, prose=True):
    n = 0
    rules = ((MODIFIER, 'syntax'), (TICKED, '`syntax'), (RETURN, '-> syntax')) if prose else ((MODIFIER, 'syntax'),)
    for rx, rep in rules:
        text, k = rx.subn(rep, text)
        n += k
    text = ARTICLE.sub(lambda m: m.group(1) + ' ' + m.group(2), text)
    return text, n


def files(paths):
    for p in paths:
        if os.path.isfile(p):
            yield p
            continue
        for root, dirs, names in os.walk(p):
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'zig-out']
            for name in sorted(names):
                if name.endswith(EXTS):
                    yield os.path.join(root, name)


def main(argv):
    check = '--check' in argv
    paths = [a for a in argv if a != '--check']
    if not paths:
        print(__doc__.strip().splitlines()[-1].strip(), file=sys.stderr)
        return 2
    for path in files(paths):
        with open(path, encoding='utf-8') as f:
            text = f.read()
        out, n = rewrite(text, prose=not path.endswith('.zig'))
        if out == text:
            continue
        print(f'{path}: {n} sites')
        if not check:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(out)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
