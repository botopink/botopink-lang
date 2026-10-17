#!/usr/bin/env python3
"""Decision 604's migration: a bodyless decorator becomes a marker with an empty body.

`declare fn name(comptime decl: @Decl, …);` (or `expr decl: …`, B-136's spelling)
becomes `fn name(…same parameters…) {}`, keeping its visibility (`pub`), its
generics, its return type and the doc comments and annotations above it. A
`declare fn` whose first parameter is not the declaration handle is left alone.

A `.bp` file is rewritten in place. Paths are files or directories (walked for
`.bp`). `--check` writes nothing and lists what it would rewrite; every site is
printed as `path:line: name`.

    scripts/codemod/bodyless-decorators.py libs/std conformance
"""
import os
import re
import sys

SITE = re.compile(
    r'^(?P<ind>[ \t]*)(?P<pub>pub\s+)?declare\s+fn\s+(?P<name>\w+)'
    r'(?P<gen><[^>(]*>)?\s*\(\s*(?:comptime|expr)\s+\w+\s*:\s*(?:@Decl|Decl|unknown)\b'
    r'(?P<rest>[^;{]*?);[ \t]*$',
    re.M | re.S,
)


def rewrite(text):
    sites = []

    # Rewrite `declare fn` → `fn`, keeping `pub`; the signature stays as written.
    def sub2(m):
        line = text.count('\n', 0, m.start()) + 1
        sites.append((line, m.group('name')))
        body = m.group(0)
        body = re.sub(r'declare\s+fn', 'fn', body, count=1)
        return body[:-1].rstrip() + ' {}'

    return SITE.sub(sub2, text), sites


def files(paths):
    for p in paths:
        if os.path.isdir(p):
            for root, _, names in os.walk(p):
                for n in sorted(names):
                    if n.endswith('.bp'):
                        yield os.path.join(root, n)
        else:
            yield p


def main(argv):
    check = '--check' in argv
    paths = [a for a in argv if a != '--check']
    total = 0
    for f in files(paths):
        with open(f, encoding='utf-8') as fh:
            text = fh.read()
        out, sites = rewrite(text)
        if not sites:
            continue
        total += len(sites)
        for line, name in sites:
            print(f'{f}:{line}: {name}')
        if not check:
            with open(f, 'w', encoding='utf-8') as fh:
                fh.write(out)
    print(f'{total} site(s)', file=sys.stderr)


if __name__ == '__main__':
    main(sys.argv[1:])
