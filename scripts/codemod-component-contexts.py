#!/usr/bin/env python3
"""Decision 354 codemod: one wrapper, `@Component<R>`, and contexts provided by a hook.

    fn Card() -> @Component<ElementBase, Element>    ->  fn Card() -> @Component<Element>
    type Element(…) implement @Context<ElementBase>  ->  type Element(…) implement @Renderable
    val ctx = use @getContext(BasePagamento);        ->  reported, left as written

The base parameter of decision 128 is gone: `@Component<C, R>` keeps its `R`
(the second argument, whatever it nests — `#(…)`, `fn(…) -> T`, `@Result<…>`).
The owner marker `@Context<C>` is `@Renderable`, the marker a component's `R`
implements. `use @getContext(T)` has no mechanical rewrite: the context it
read becomes a `Context<T>` object read with `use context(…)` under a
`use provide(…)`, and which component provides it is the author's choice — so
each one is printed `UNDECIDED <file>:<line>` and the run exits 1.

The rewrite is textual, over code, comments and string literals alike (a
reflected return type compared as text, `"@Component<ElementBase, Element>"`,
is the same spelling), so a commented example stays true. A `@Component` with
one argument is already the new form and is left alone.

    scripts/codemod-component-contexts.py [--write] [--format BOTOPINK] [--ext EXT]... ROOT...

ROOT is a file or a directory (walked, hidden and build directories skipped).
The files read are `.bp`, `.d.bp` and `.bp.fixture`, plus every `--ext` given
(`--ext .md --ext .zig` for documentation and the compiler's own test
sources). Without `--write` it only reports. With `--format`, each `.bp` /
`.d.bp` file it changed that `botopink format --check` accepted before is
formatted after, so the trees stay canonical.
"""
import os
import re
import subprocess
import sys

SKIP_DIRS = {".botopinkbuild", "node_modules", "out", "zig-out", ".zig-cache", ".git"}
BASE_EXTS = (".bp", ".d.bp", ".bp.fixture")
OPEN = {"<": ">", "(": ")", "[": "]", "{": "}"}
CLOSE = {v: k for k, v in OPEN.items()}


def generic_args(text, start):
    """`start` indexes the `<` after a builtin name. Answers (args, end) where
    `args` is each top-level argument's (begin, end) span and `end` indexes the
    closing `>`; None when the list does not close on this text."""
    depth = []
    args = []
    arg_begin = start + 1
    i = start + 1
    n = len(text)
    while i < n:
        c = text[i]
        if c == "-" and i + 1 < n and text[i + 1] == ">":
            i += 2  # `fn(…) -> T`: the arrow closes nothing
            continue
        if c in OPEN:
            depth.append(OPEN[c])
        elif c in CLOSE:
            if not depth:
                if c != ">":
                    return None
                if text[arg_begin:i].strip() or not args:
                    args.append((arg_begin, i))  # a trailing `,` adds no argument
                return args, i
            if depth[-1] != c:
                return None
            depth.pop()
        elif c == "," and not depth:
            args.append((arg_begin, i))
            arg_begin = i + 1
        i += 1
    return None


def rewrite(text):
    """Answers (new_text, component_rewrites, context_rewrites, getcontext_lines)."""
    out = []
    i = 0
    comps = ctxs = 0
    undecided = []
    n = len(text)
    while i < n:
        if text.startswith("@Component<", i):
            lt = i + len("@Component")
            parsed = generic_args(text, lt)
            if parsed is not None and len(parsed[0]) == 2:
                (_, _), (b, e) = parsed[0]
                # The kept argument on one line: a comment's `//` that broke it
                # (`@Component<Base,\n// T>`) and a multi-line layout both fold.
                kept = re.sub(r"\s*\n\s*(?://+\s*)?", " ", text[b:e]).strip()
                out.append("@Component<" + kept + ">")
                i = parsed[1] + 1
                comps += 1
                continue
        if text.startswith("@Context<", i):
            lt = i + len("@Context")
            parsed = generic_args(text, lt)
            if parsed is not None:
                out.append("@Renderable")
                i = parsed[1] + 1
                ctxs += 1
                continue
        if text.startswith("@getContext(", i):
            line_start = text.rfind("\n", 0, i) + 1
            if "//" not in text[line_start:i]:  # prose about it is not a use
                undecided.append(text.count("\n", 0, i) + 1)
        out.append(text[i])
        i += 1
    return "".join(out), comps, ctxs, undecided


def wanted(path, exts):
    return path.endswith(BASE_EXTS) or any(path.endswith(e) for e in exts)


def walk(root, exts):
    if os.path.isfile(root):
        yield root
        return
    for d, dirs, files in os.walk(root):
        dirs[:] = sorted(x for x in dirs if not x.startswith(".") and x not in SKIP_DIRS)
        for f in sorted(files):
            p = os.path.join(d, f)
            if wanted(p, exts):
                yield p


def canonical(botopink, path):
    r = subprocess.run([botopink, "format", "--check", path], capture_output=True)
    return r.returncode == 0


def main(argv):
    write = False
    fmt = None
    exts = []
    roots = []
    i = 0
    while i < len(argv):
        a = argv[i]
        if a == "--write":
            write = True
        elif a == "--format":
            i += 1
            fmt = argv[i]
        elif a == "--ext":
            i += 1
            exts.append(argv[i])
        elif a in ("-h", "--help"):
            print(__doc__)
            return 0
        else:
            roots.append(a)
        i += 1
    if not roots:
        print(__doc__, file=sys.stderr)
        return 2
    files = changed = comps = ctxs = 0
    undecided = []
    for root in roots:
        for path in walk(root, exts):
            files += 1
            with open(path, encoding="utf-8") as f:
                text = f.read()
            new, c, x, und = rewrite(text)
            for line in und:
                undecided.append((path, line))
            if new == text:
                continue
            changed += 1
            comps += c
            ctxs += x
            print(f"rewrite {path}: {c} @Component<C, R>, {x} @Context<C>")
            if not write:
                continue
            was_canonical = fmt is not None and path.endswith((".bp", ".d.bp")) and canonical(fmt, path)
            with open(path, "w", encoding="utf-8") as f:
                f.write(new)
            if was_canonical:
                subprocess.run([fmt, "format", path], check=False, capture_output=True)
    for path, line in undecided:
        print(f"UNDECIDED {path}:{line} `use @getContext(T)` — declare a `Context<T>`, provide it with `use provide(…)` in the component that renders the reader, and read it with `use context(…)` (decision 354)")
    print(f"{files} file(s) read, {changed} changed: {comps} @Component<C, R> -> @Component<R>, {ctxs} @Context<C> -> @Renderable, {len(undecided)} undecided")
    return 1 if undecided else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
