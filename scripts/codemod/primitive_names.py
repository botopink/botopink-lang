#!/usr/bin/env python3
"""144 B-148's codemod: decision 641 — every primitive type is written lowercase, and `String`,
`Bool`, `BigInt`, `Bytes` and `Array` dissolve into their types, which hold their statics.

    Array<T>                 ->  array<T>                  (the type; `T[]` stays as written)
    Array.range(0, 3)        ->  array.range(0, 3)         (a static, `.` after any whitespace)
    String.fromCodepoint(c)  ->  string.fromCodepoint(c)
    Bool.<m> / BigInt.<m>    ->  bool.<m> / bigint.<m>
    Bytes                    ->  bytes                     (the type, and `Bytes.fromUtf8(s)`)
    implement S for String   ->  implement S for string    (and `for Array<T>`, `for Bool`, …)

Every rewrite keeps the text's length, so no line or column moves and a cell's recorded
locations stay right. String contents are never rewritten (a `${…}` hole is code): a host
template's `String.fromCodePoint`, `Array.from`, `BigInt(…)` are the host's. In a `//` or `///`
comment, only a code span (`` `…` ``) is respelled, and only `Array<`, `Bytes` and the statics the
types hold (`String.fromCodepoint`, `Array.range`, `Array.repeat`, `Bytes.fromUtf8`,
`BigInt.of`, `BigInt.parse`): `String.prototype` is the host's. A `////` line is a cell's
reference, the ledger's text, and is left as written.

Left as written, each listed as `LEFT <path>:<line> <why>`:

* a name after a `.` (`Json.Bool(value: true)`, a variant or a member of another type);
* `Bytes(` and every other use of the five names (`Bool(value: x)`, a variant; `behavior X
  extends String`, which has no lowercase form: `string` is a type, not a contract);
* every site of a name the file declares itself (`type Bytes`, `behavior String`, an enum's
  `Bool(…)` variant) — the file's own name, not the prelude's;
* a static (`Bytes.fromUtf8(…)`) in a file that binds the lowercase name (`val bytes = …`, a
  parameter or a lambda's `bytes`): in that binding's scope `bytes.fromUtf8` reads the binding,
  which shadows the type — rename the binding, then rerun.

    scripts/codemod/primitive_names.py [--check] [--zig] PATH...

Without a flag it rewrites every `.bp` file under each PATH in place and prints the per-rule
counts. `--check` writes nothing, lists each file it would change and exits 1 when one would.
`--zig` rewrites the botopink sources a `.zig` test writes as `\\\\` lines and its one-line `"…"`
literals instead; a file whose `\\\\` lines are not botopink (`js_prelude.zig`'s JavaScript) and
the parser's and the formatter's tests (they parse, never resolve a name) are skipped.
"""
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compiler_keyword import mask  # noqa: E402
from prelude_names import SKIP_DIRS, ZIG_LINE  # noqa: E402

NAMES = {"String": "string", "Array": "array", "Bool": "bool", "BigInt": "bigint", "Bytes": "bytes"}
NAME = re.compile(r"\b(String|Array|Bool|BigInt|Bytes)\b")
# The cells whose sources write a capitalised name on purpose: decision 641's own refusal.
SKIP_CELLS = (
    "conformance/modules/decisions-taken/primitive_types_lowercase-641/cells/primitive_contract_dissolved/",
)
# `.zig` files whose `\\\\` lines are no botopink source, or whose sources are parsed only.
ZIG_SKIP = ("/codegen/js/", "/src/parser/", "/src/format/", "/lexer/", "/scripts/")


def declared(m):
    """The five names the file declares itself: a type, a behavior, a value, a function, a variant."""
    own = set(re.findall(r"\b(?:type|behavior|val|var|fn)\s+(String|Array|Bool|BigInt|Bytes)\b", m))
    # An enum variant: the name at the start of a line inside a type's braces, then `(` or `,`.
    own |= set(re.findall(r"^\s*(String|Array|Bool|BigInt|Bytes)\s*(?:\(|,|\n)", m, re.M))
    return own


def bound_lowercase(m):
    """The lowercase names the file binds as values in a body: a `val` / `var`, a parameter of a
    function that is no `declare fn`, a lambda's parameter."""
    names = "|".join(NAMES.values())
    own = set(re.findall(r"\b(?:val|var)\s+(%s)\b" % names, m))
    own |= set(re.findall(r"\{\s*(?:\w+\s*,\s*)*(%s)\s*(?:,|->)" % names, m))
    for line in m.split("\n"):
        if "declare" in line:
            continue
        own |= set(re.findall(r"[(,]\s*(%s)\s*:" % names, line))
    return own


def line_of(text, p):
    return text.count("\n", 0, p) + 1


def rewrite(text):
    """(new text, counts, left) — `left` a list of (line, why)."""
    m = mask(text)
    own = declared(m)
    shadowing = bound_lowercase(m)
    counts, left, edits = collections.Counter(), [], []
    for mo in NAME.finditer(m):
        a, b, name = mo.start(), mo.end(), mo.group(1)
        before = m[:a].rstrip()
        after = m[b:].lstrip()
        if name in own:
            left.append((line_of(text, a), "`%s`: the file declares its own" % name))
            continue
        if before.endswith(".") or before.endswith("@"):
            continue  # `Json.Bool`, a member or a variant of another type
        if re.search(r"\b(?:for|implement)$", before):
            edits.append((a, b, NAMES[name]))
            counts["for %s -> for %s" % (name, NAMES[name])] += 1
            continue
        if after.startswith("<") and name == "Array":
            edits.append((a, b, NAMES[name]))
            counts["Array<…> -> array<…>"] += 1
            continue
        if after.startswith(".") and not after.startswith(".."):
            if NAMES[name] in shadowing:
                left.append((line_of(text, a), "`%s.`: the file binds `%s`, which shadows the type where it is in scope" % (name, NAMES[name])))
                continue
            edits.append((a, b, NAMES[name]))
            counts["%s.<static> -> %s.<static>" % (name, NAMES[name])] += 1
            continue
        if name == "Bytes" and not after.startswith("("):
            edits.append((a, b, NAMES[name]))
            counts["Bytes -> bytes"] += 1
            continue
        if re.search(r"\bextends$", before):
            left.append((line_of(text, a), "`extends %s`: `%s` is a type, not a contract" % (name, NAMES[name])))
        elif not after.startswith("("):
            left.append((line_of(text, a), "`%s` in another position" % name))
        # `Bool(value: x)` and its siblings: a variant of the file's or an imported type.
    out, at = [], 0
    for a, b, t in sorted(edits):
        out.append(text[at:a])
        out.append(t)
        at = b
    out.append(text[at:])
    return "".join(out), counts, left


PROSE_STATIC = re.compile(r"\b(String|Array|Bytes|BigInt|Bool)\.(fromCodepoint|range|repeat|fromUtf8|of|parse)\b")
SPAN = re.compile(r"`[^`\n]*`")


def prose_span(t, counts):
    def one(mo):
        span = mo.group(0)
        new = PROSE_STATIC.sub(lambda x: NAMES[x.group(1)] + "." + x.group(2), span)
        new = re.sub(r"\bArray<", "array<", new)
        new = re.sub(r"\bBytes\b", "bytes", new)
        if new != span:
            counts["prose: a code span"] += 1
        return new
    return SPAN.sub(one, t)


def rewrite_prose(text):
    """`text` with the code spans of its `//` and `///` comments respelled (same length)."""
    m = mask(text)
    counts = collections.Counter()
    out, pos = [], 0
    starts = [0] + [i + 1 for i, c in enumerate(text) if c == "\n"]
    for ls in starts:
        le = text.find("\n", ls)
        le = len(text) if le < 0 else le
        line = text[ls:le]
        k = line.find("//")
        while k >= 0 and m[ls + k:ls + k + 2] != "  ":
            k = line.find("//", k + 2)
        if k < 0 or line[k:].startswith("////"):
            continue
        new = line[:k] + prose_span(line[k:], counts)
        if new != line:
            out.append(text[pos:ls])
            out.append(new)
            pos = le
    out.append(text[pos:])
    return "".join(out), counts


ZIG_STRING = re.compile(r'"((?:[^"\\\n]|\\.)*)"')


def rewrite_zig(text):
    lines = text.split("\n")
    out, i, counts, left = [], 0, collections.Counter(), []
    while i < len(lines):
        if not ZIG_LINE.match(lines[i]):
            line = lines[i]
            # A one-line literal holding botopink source (`"pub fn main() -> void { val b: Bytes
            # = …"`): each literal's text rewritten as a `.bp` text; a rewrite keeps the length,
            # so offsets stay. A comment, and a literal with no `fn` / `val` / `var` / `import`
            # (a message, a test's name, an expected `.d.ts` line), are no source.
            if line.lstrip().startswith("//"):
                out.append(line)
                i += 1
                continue
            new_line, at = [], 0
            for mo in ZIG_STRING.finditer(line):
                src = mo.group(1)
                if not NAME.search(src) or not re.search(r"\b(?:fn|val|var|import)\b", src):
                    continue
                new, c, lf = rewrite(src)
                counts.update(c)
                left += [(i + 1, why) for _, why in lf]
                if new == src:
                    continue
                new_line.append(line[at:mo.start(1)])
                new_line.append(new)
                at = mo.end(1)
            new_line.append(line[at:])
            out.append("".join(new_line))
            i += 1
            continue
        j = i
        while j < len(lines) and ZIG_LINE.match(lines[j]):
            j += 1
        block = lines[i:j]
        prefix = ZIG_LINE.match(block[0]).group(1)
        src = "\n".join(ZIG_LINE.match(ln).group(2) for ln in block)
        new, c, lf = rewrite(src)
        counts.update(c)
        left += [(i + ln, why) for ln, why in lf]
        if new != src:
            new_lines = new.split("\n")
            out.extend(ZIG_LINE.match(old).group(1) + nl for old, nl in zip(block, new_lines))
        else:
            out.extend(block)
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
                norm = os.path.abspath(path).replace(os.sep, "/")
                if not f.endswith(ext) or any(c in norm for c in SKIP_CELLS):
                    continue
                if ext == ".zig" and any(s in norm for s in ZIG_SKIP):
                    continue
                yield path


def main(argv):
    check, zig = "--check" in argv, "--zig" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    total, changed, nleft = collections.Counter(), 0, 0
    for path in files_under(paths, ".zig" if zig else ".bp"):
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        new, counts, left = rewrite_zig(text) if zig else rewrite(text)
        if not zig:
            new, pc = rewrite_prose(new)
            counts.update(pc)
        for ln, why in left:
            print("LEFT %s:%d %s" % (path, ln, why))
            nleft += 1
        total.update(counts)
        if new == text:
            continue
        changed += 1
        if check:
            print("WOULD CHANGE %s (%d)" % (path, sum(counts.values())))
            continue
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new)
    for rule, n in sorted(total.items()):
        print("%6d  %s" % (n, rule))
    print("%6d  sites" % sum(total.values()))
    print("%6d  files %s" % (changed, "to change" if check else "changed"))
    print("%6d  sites left" % nleft)
    return 1 if check and changed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
