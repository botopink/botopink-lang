#!/usr/bin/env python3
"""Decision 575 (6)'s migration: `#[@External.X(…)]` → `#[@external(.X(…))]`.

Every `@External.<Target>(…)` annotation of one declaration becomes one source
of a single `#[@external(…)]` (`#[external(…)]` inside `libs/std/src`, which
writes no `@`), written where the first of them stood; the declaration's other
annotations keep their places. Each source keeps its arguments and their
labels, in the order the enum's constructor takes them — the positional ones
first, then the labelled ones as written — with two rewrites:

- `fn: <name>` → `body: <name>` (`fn` is a reserved word, no field's name);
- the two-string form `("<module>", "<symbol>")` → one template over the
  declared parameters, the receiver first on a method:
  `.Erlang("<module>:<symbol>($0, $1)")`, `.Node("<module>.<symbol>($0)")`.

A `.bp` file is rewritten in place. A `.zig` file's `\\\\` line strings are
rewritten as the `.bp` text they hold, each run of them one document; a `.snap`
/ `.snap.md` file is never touched. Paths are files or directories (walked for
`.bp`; `.zig` only when named). `--check` writes nothing and lists what it would
rewrite. What it cannot rewrite (a two-string form whose module is a path) is
listed on stderr and left as written.

    scripts/codemod/external-implementations.py libs/std/src conformance
"""
import os
import re
import sys

VARIANT = re.compile(r'@?External\.([A-Za-z]+)\s*\(')


def skip_string(s, i):
    """The index after the string literal starting at s[i] (`"…"` or `\"\"\"…\"\"\"`)."""
    if s.startswith('"""', i):
        j = s.find('"""', i + 3)
        return len(s) if j < 0 else j + 3
    j = i + 1
    while j < len(s):
        c = s[j]
        if c == '\\':
            j += 2
            continue
        if c == '"':
            return j + 1
        if c == '\n':
            return j
        j += 1
    return j


def skip_comment(s, i):
    j = s.find('\n', i)
    return len(s) if j < 0 else j


def matching(s, i, open_c, close_c):
    """The index of the bracket closing the one at s[i]."""
    depth = 0
    j = i
    while j < len(s):
        c = s[j]
        if c == '"':
            j = skip_string(s, j)
            continue
        if s.startswith('//', j):
            j = skip_comment(s, j)
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
            if depth == 0:
                return j
        j += 1
    return -1


def split_top(s):
    """`s` split at its top-level commas, each piece with its offset."""
    out = []
    depth = 0
    start = 0
    j = 0
    while j < len(s):
        c = s[j]
        if c == '"':
            j = skip_string(s, j)
            continue
        if s.startswith('//', j):
            j = skip_comment(s, j)
            continue
        if c in '([{':
            depth += 1
        elif c in ')]}':
            depth -= 1
        elif c == ',' and depth == 0:
            out.append((start, s[start:j]))
            start = j + 1
        j += 1
    if s[start:].strip():
        out.append((start, s[start:]))
    return out


LABEL = re.compile(r'^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:(?!:)\s*(.*)$', re.S)


def parse_args(text):
    """[(label or None, value)] of an argument list's text."""
    args = []
    for _, piece in split_top(text):
        p = piece.strip()
        if not p:
            continue
        m = LABEL.match(p)
        if m and not p.startswith('"'):
            args.append((m.group(1), m.group(2).strip()))
        else:
            args.append((None, p))
    return args


def is_string(v):
    return v.startswith('"') and v.endswith('"') and len(v) >= 2


class Params(list):
    """A declaration's parameter names; `variadic` when its last is `..xs`."""
    def __init__(self, names, variadic):
        super().__init__(names)
        self.variadic = variadic


def params_after(s, i):
    """The parameter names of the `fn` declared after s[i:], and whether it is a method."""
    m = re.compile(r'\bfn\s+[A-Za-z_][A-Za-z0-9_]*\s*(<[^>(]*>)?\s*\(').search(s, i)
    if not m:
        return None
    open_at = m.end() - 1
    close_at = matching(s, open_at, '(', ')')
    if close_at < 0:
        return None
    names = []
    variadic = [False]
    for _, piece in split_top(s[open_at + 1:close_at]):
        p = piece.strip()
        p = re.sub(r'^(comptime|expr)\s+', '', p)
        if p.startswith('..'):
            variadic[0] = True
        p = p.lstrip('.')
        n = re.match(r'([A-Za-z_][A-Za-z0-9_]*)', p)
        if n:
            names.append(n.group(1))
    return Params(names, variadic[0])


# commonJS's `js_global_namespaces`: a module of these is no `require`.
JS_GLOBALS = {"globalThis", "Math", "JSON", "console", "Number", "Date", "Object", "Array", "String",
              "Boolean", "Symbol", "BigInt", "Promise", "Reflect", "Intl", "Error", "RegExp", "Map",
              "Set", "WeakMap", "WeakSet", "Atomics", "process", "Uint8Array"}


def two_string_template(target, module, symbol, params):
    mod = module[1:-1]
    sym = symbol[1:-1]
    if '/' in mod or mod.endswith('.mjs') or mod.endswith('.js'):
        return None
    markers = ', '.join('$%d' % k for k in range(len(params)))
    # `"sym(a, self)"` names the host's argument order by parameter name.
    m = re.match(r'^([A-Za-z_][A-Za-z0-9_]*)\((.*)\)$', sym)
    if m:
        names = [x.strip() for x in m.group(2).split(',') if x.strip()]
        if not all(n in params for n in names):
            return None
        sym = m.group(1)
        markers = ', '.join('$%d' % params.index(n) for n in names)
    if target == 'Erlang':
        return '"%s:%s(%s)"' % (mod, sym, markers)
    if target in ('Node', 'Typescript'):
        # A JS host takes a variadic's values one by one; erlang takes the list.
        if getattr(params, 'variadic', False) and not m:
            markers = '$args'
        if mod in JS_GLOBALS:
            return '"%s.%s(%s)"' % (mod, sym, markers)
        # A module the program requires (`node:path`).
        return '"""require("%s").%s(%s)"""' % (mod, sym, markers)
    return None


def rewrite_source(target, args_text, params, where, problems):
    args = parse_args(args_text)
    positional = [v for (l, v) in args if l is None]
    labelled = [(l, v) for (l, v) in args if l is not None]
    # The keyword form `module: "m", method: "s"` is the two-string form.
    kw = dict(labelled)
    if not positional and 'module' in kw and 'method' in kw:
        positional = [kw['module'], kw['method']]
        labelled = [(l, v) for (l, v) in labelled if l not in ('module', 'method')]
    if len(positional) == 2 and all(is_string(v) for v in positional) and params is not None:
        t = two_string_template(target, positional[0], positional[1], params)
        if t is None:
            problems.append('%s: `.%s(%s, %s)` has no one-template form (a module path, or no such target); left as written' % (where, target, positional[0], positional[1]))
        else:
            positional = [t]
    # A template is a string now: a host `${` is written `\${`.
    positional = [v.replace('${', '\\${') if is_string(v) else v for v in positional]
    parts = list(positional)
    for (l, v) in labelled:
        if l == 'fn':
            l = 'body'
        parts.append('%s: %s' % (l, v))
    return '.%s(%s)' % (target, ', '.join(parts))


def find_blocks(s):
    """Every annotation block `#[…]`: (start, end_exclusive)."""
    blocks = []
    j = 0
    while j < len(s):
        c = s[j]
        if c == '"':
            j = skip_string(s, j)
            continue
        if s.startswith('//', j):
            j = skip_comment(s, j)
            continue
        if s.startswith('#[', j):
            close = matching(s, j + 1, '[', ']')
            if close < 0:
                break
            blocks.append((j, close + 1))
            j = close + 1
            continue
        j += 1
    return blocks


def only_trivia(s):
    """True when s is whitespace and `//` comments only."""
    for line in s.split('\n'):
        t = line.strip()
        if t and not t.startswith('//'):
            return False
    return True


def rewrite_bp(s, in_std, where):
    problems = []
    blocks = find_blocks(s)
    if not blocks:
        return s, problems
    # Group the blocks one declaration carries: consecutive, trivia between.
    groups = []
    for b in blocks:
        if groups and only_trivia(s[groups[-1][-1][1]:b[0]]):
            groups[-1].append(b)
        else:
            groups.append([b])
    edits = []  # (start, end, replacement)
    for g in groups:
        items = []  # (block index, item text, is_external, target, args_text)
        for bi, (a, b) in enumerate(g):
            inner = s[a + 2:b - 1]
            for _, piece in split_top(inner):
                p = piece.strip()
                m = VARIANT.match(p)
                if m and p.endswith(')'):
                    open_at = m.end() - 1
                    close_at = matching(p, open_at, '(', ')')
                    if close_at == len(p) - 1:
                        items.append((bi, p, True, m.group(1), p[open_at + 1:close_at]))
                        continue
                items.append((bi, p, False, None, None))
        if not any(x[2] for x in items):
            continue
        params = params_after(s, g[-1][1])
        line_no = s.count('\n', 0, g[0][0]) + 1
        sources = [rewrite_source(t, at, params, '%s:%d' % (where, line_no), problems) for (_, _, ext, t, at) in items if ext]
        name = 'external' if in_std else '@external'
        first_ext_block = next(x[0] for x in items if x[2])
        # Each block keeps its non-external items; the first block holding an
        # external item is followed by the merged one.
        for bi, (a, b) in enumerate(g):
            kept = [x[1] for x in items if x[0] == bi and not x[2]]
            had_ext = any(x[2] for x in items if x[0] == bi)
            if not had_ext:
                continue
            line_start = s.rfind('\n', 0, a) + 1
            indent = s[line_start:a]
            if indent.strip():
                indent = re.match(r'\s*', indent).group(0)
            text_parts = []
            if kept:
                text_parts.append('#[' + ', '.join(kept) + ']')
            if bi == first_ext_block:
                one = '#[%s(%s)]' % (name, ', '.join(sources))
                if len(indent) + len(one) > 100 or any('\n' in x for x in sources):
                    one = '#[%s(\n%s%s,\n%s)]' % (name, indent + '    ', (',\n' + indent + '    ').join(sources), indent)
                text_parts.append(one)
            if text_parts:
                edits.append((a, b, ('\n' + indent).join(text_parts)))
            else:
                # Drop the block and its line when nothing else is on it.
                line_end = s.find('\n', b)
                line_end = len(s) if line_end < 0 else line_end
                if s[line_start:a].strip() == '' and s[b:line_end].strip() == '':
                    edits.append((line_start, min(line_end + 1, len(s)), ''))
                else:
                    edits.append((a, b, ''))
    out = s
    for (a, b, r) in sorted(edits, key=lambda e: e[0], reverse=True):
        out = out[:a] + r + out[b:]
    return out, problems


ZIG_LINE = re.compile(r'^(\s*)\\\\(.*)$')


def rewrite_zig(s, where):
    lines = s.split('\n')
    out = []
    problems = []
    i = 0
    while i < len(lines):
        m = ZIG_LINE.match(lines[i])
        if not m:
            out.append(lines[i])
            i += 1
            continue
        j = i
        run = []
        while j < len(lines):
            mm = ZIG_LINE.match(lines[j])
            if not mm:
                break
            run.append(mm)
            j += 1
        doc = '\n'.join(x.group(2) for x in run)
        if 'External.' in doc:
            new, probs = rewrite_bp(doc, False, '%s:%d' % (where, i + 1))
            problems += probs
            prefix = run[0].group(1)
            out += [prefix + '\\\\' + x for x in new.split('\n')]
        else:
            out += lines[i:j]
        i = j
    return '\n'.join(out), problems


def files_of(paths):
    for p in paths:
        if os.path.isfile(p):
            yield p
            continue
        for root, dirs, names in os.walk(p):
            dirs[:] = [d for d in dirs if not d.startswith('.') and d != 'node_modules']
            for n in sorted(names):
                if n.endswith('.bp'):
                    yield os.path.join(root, n)


def main(argv):
    check = '--check' in argv
    paths = [a for a in argv if not a.startswith('--')]
    if not paths:
        print(__doc__)
        return 2
    changed = 0
    problems = []
    for f in files_of(paths):
        if f.endswith('.snap') or f.endswith('.snap.md'):
            continue
        s = open(f, encoding='utf-8').read()
        if 'External.' not in s:
            continue
        if f.endswith('.zig'):
            new, probs = rewrite_zig(s, f)
        else:
            in_std = os.sep + os.path.join('libs', 'std', 'src') + os.sep in os.sep + os.path.abspath(f)
            new, probs = rewrite_bp(s, in_std, f)
        problems += probs
        if new != s:
            changed += 1
            if check:
                print(f)
            else:
                open(f, 'w', encoding='utf-8').write(new)
    for p in problems:
        print(p, file=sys.stderr)
    print('%d file(s) %s' % (changed, 'to rewrite' if check else 'rewritten'), file=sys.stderr)
    return 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
