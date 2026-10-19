#!/usr/bin/env python3
"""144 B-139's codemod: decision 606 — no `@name`. The prelude's types are written bare, the two
std functions are imported where they are used, what the compiler does is a member of `compiler`.

    @Result<…> / @Task<…> / @Component<…> / @Iterator<…> / @Stream<…>   ->  Result<…> / …
    @Renderable                         ->  Renderable
    @print(…) / @debug(…) / @println(…) ->  print(…)          + import {io.terminal.print}
    @panic(…)                           ->  panic(…)          + import {failure.panic}
    @todo() / @todo(m)                  ->  panic("not implemented") / panic(m)   (same import)
    @typeInfo(…)                        ->  comptime compiler.typeInfo(…)         + import {compiler}
    @src()                              ->  comptime compiler.src                 + import {compiler}
    #[@external(  /  #[external(        ->  #[compiler.external(                  + import {compiler}

The import is merged into the file's first `from "std"` import (inside std, the brace form
`import {…};`), or written after its last import, or after its leading comment block. A file
that declares or imports a name the rewrite would bind (its own `fn print`, `type Result`) keeps
that site as written and is reported (`UNDECIDED`). A module that declares the function itself
(`io/terminal.bp`, `failure.bp`, `compiler.bp`) imports nothing for it.

Comments (`//`, `///`, `////`) and `test "…"` names are respelled too: the `@Type` names, `#[@External.<T>(…)]`,
`@External.<T>`, `@print` / `@panic` / `@typeInfo` (a `////` line is the cell's reference). The cells
that refuse an old spelling (SKIP_CELLS) are never touched. `@Expr`, `@Decl` and `@Stage` stay in prose.

Left as written, and counted: `@TypeInfo.all` (the catalogue — 144 B-137's `compiler.find`),
`@embed` (607: `comptime Asset(compiler.embed(p))` and its reads over `File` are each cell's),
`@emit` / `@code` / `@expr` (605), the removed effect annotations (`#[@use]`, `#[@future]`, …),
`#[@Stage.…]` / `#[@BeamMemory.…]`, and anything inside a comment or a string.

    scripts/codemod/prelude_names.py [--check] [--zig] [--snapshots] PATH...

Without a flag it rewrites every `.bp` file under each PATH in place and prints the per-rule
counts. `--check` writes nothing and exits 1 when a file would change. `--zig` rewrites the
botopink sources a `.zig` test writes as `\\\\` lines instead (each block's import is written as
its last line, so no line of the block moves). `--snapshots` moves the `at` / `from` locations
of each rewritten cell's `snapshot/**.snap` (a cell is a directory holding `botopink.json` and
`snapshot/`) with the text they point into.
"""
import bisect
import collections
import os
import re
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compiler_keyword import mask, match_close, skip_ws  # noqa: E402

SKIP_DIRS = {".botopinkbuild", "node_modules", "out", "zig-out", ".zig-cache", ".git", "snapshot"}
# The declarations the compiler still reads by name (B-139's removal piece deletes them).
SKIP_FILES = ("std/src/builtins.d.bp", "std/src/builtins_fns.d.bp")
# The cells whose sources write the spelling a refusal is about, on purpose.
SKIP_CELLS = ("conformance/modules/external_beam_removed/", "conformance/modules/builtin_print_removed/", "conformance/modules/prelude_name_with_sigil/")

WRAPPERS = ("Result", "Task", "Component", "Iterator", "Stream")
PRINTS = ("print", "debug", "println")

# The import each name needs, and the std module that declares it.
IMPORTS = {
    "print": ("io.terminal.print", "io/terminal"),
    "panic": ("failure.panic", "failure"),
    "compiler": ("compiler", "compiler"),
}

TARGETS = {"Beam": "Erlang", "Erlang": "Erlang", "Node": "JavaScript", "JavaScript": "JavaScript", "Wasm": "Wasm"}

LEFT = ("TypeInfo", "embed", "emit", "code", "expr", "Stage", "BeamMemory", "field", "TypeOf",
        "makeRecord", "RecordKeys", "comptimeError", "compilerError", "trap", "module")


def std_key(path):
    p = os.path.abspath(path).replace(os.sep, "/")
    k = p.find("/libs/std/src/")
    if k < 0:
        return None
    rel = p[k + len("/libs/std/src/"):]
    return rel[:-3] if rel.endswith(".bp") else rel


def declared_names(m):
    """Names the file declares (`fn print`, `type Result`, a `val`) or imports."""
    own = set(re.findall(r"^(?:pub\s+)?(?:default\s+)?(?:declare\s+)?(?:type|behavior|val|var|fn)\s+(\w+)", m, re.M))
    for mo in re.finditer(r"\bimport\s*\{([^}]*)\}", m):
        for item in re.split(r"[,{}:]", mo.group(1)):
            item = item.strip()
            if not item:
                continue
            al = re.search(r"\bas\s+(\w+)$", item)
            own.add(al.group(1) if al else item.split(".")[-1])
    return own


def imported_items(m):
    items = set()
    for mo in re.finditer(r"\bimport\s*\{([^}]*)\}", m):
        for item in mo.group(1).split(","):
            items.add(re.sub(r"\s+as\s+\w+$", "", item.strip()))
    return items


class Edits:
    def __init__(self):
        self.edits = []  # (start, end, text)

    def add(self, a, b, t):
        self.edits.append((a, b, t))

    def apply(self, text):
        out, at = [], 0
        for a, b, t in sorted(self.edits):
            assert a >= at, "overlapping edits"
            out.append(text[at:a])
            out.append(t)
            at = b
        out.append(text[at:])
        return "".join(out)


def rewrite(text, key):
    """(new text, counts, undecided, edits) — `key` the std module's key, or None."""
    m = mask(text)
    counts = collections.Counter()
    undecided = []
    ed = Edits()
    own = declared_names(m)
    imported = imported_items(m)
    needs = []
    # The name the file already binds `compiler` to (`import {compiler as c}`).
    cname = None
    for imo in re.finditer(r"\bimport\s*\{([^}]*)\}", m):
        for item in imo.group(1).split(","):
            al = re.fullmatch(r"\s*compiler(?:\s+as\s+(\w+))?\s*", item)
            if al:
                cname = al.group(1) or "compiler"

    def line_of(p):
        return text.count("\n", 0, p) + 1

    def need(name):
        if key == IMPORTS[name][1]:
            return  # the module declares it
        if IMPORTS[name][0] in imported:
            return
        if name not in needs:
            needs.append(name)

    def clashes(name, p, rule):
        if key == IMPORTS[name][1]:
            return False
        if name in own and IMPORTS[name][0] not in imported:
            undecided.append((line_of(p), "%s: the file declares or imports its own `%s`" % (rule, name)))
            return True
        return False

    for mo in re.finditer(r"@([A-Za-z_]\w*)", m):
        a = mo.start()
        name = mo.group(1)
        # `#[@x` is an annotation; `@`…`` a template text (no name follows).
        ann = m[max(0, a - 2):a] == "#["
        if ann:
            em = re.match(r"External\.(\w+)\s*\(", m[a + 1:]) if name == "External" else None
            if em:
                op = a + 1 + em.end() - 1
                close = match_close(m, op)
                if close < 0:
                    undecided.append((line_of(a), "#[@External: no closing parenthesis"))
                    continue
                if cname is None and clashes("compiler", a, "#[@External"):
                    continue
                ed.add(a, a + 1 + em.end(), (cname or "compiler") + ".external(." + TARGETS.get(em.group(1), em.group(1)) + "(")
                ed.add(close + 1, close + 1, ")")
                if cname is None:
                    need("compiler")
                counts["#[@External.<T>(…) -> #[compiler.external(.<T>(…))"] += 1
            elif name == "external":
                if cname is None and clashes("compiler", a, "#[@external"):
                    continue
                ed.add(a, mo.end(), (cname or "compiler") + ".external")
                if cname is None:
                    need("compiler")
                counts["#[@external -> #[compiler.external"] += 1
            else:
                counts["left: #[@%s" % name.split(".")[0]] += 1
            continue
        after = skip_ws(m, mo.end())
        if name in WRAPPERS and after < len(m) and m[after] == "<":
            if name in own:
                undecided.append((line_of(a), "@%s: the file declares or imports its own `%s`" % (name, name)))
                continue
            ed.add(a, a + 1, "")
            counts["@%s<…> -> %s<…>" % (name, name)] += 1
        elif name == "Renderable":
            if name in own:
                undecided.append((line_of(a), "@Renderable: the file declares or imports its own `Renderable`"))
                continue
            ed.add(a, a + 1, "")
            counts["@Renderable -> Renderable"] += 1
        elif name in PRINTS and after < len(m) and m[after] == "(":
            if clashes("print", a, "@" + name):
                continue
            ed.add(a, mo.end(), "print")
            need("print")
            counts["@%s(…) -> print(…)" % name] += 1
        elif name == "panic" and after < len(m) and m[after] == "(":
            if clashes("panic", a, "@panic"):
                continue
            ed.add(a, mo.end(), "panic")
            need("panic")
            counts["@panic(…) -> panic(…)"] += 1
        elif name == "todo" and after < len(m) and m[after] == "(":
            if clashes("panic", a, "@todo"):
                continue
            close = match_close(m, after)
            if close < 0:
                undecided.append((line_of(a), "@todo: no closing parenthesis"))
                continue
            if m[after + 1:close].strip() == "":
                ed.add(a, close + 1, 'panic("not implemented")')
            else:
                ed.add(a, mo.end(), "panic")
            need("panic")
            counts["@todo(…) -> panic(…)"] += 1
        elif name == "typeInfo" and after < len(m) and m[after] == "(":
            if cname is None and clashes("compiler", a, "@typeInfo"):
                continue
            under = re.search(r"\bcomptime\s*$", m[:a]) is not None
            ed.add(a, mo.end(), ("" if under else "comptime ") + (cname or "compiler") + ".typeInfo")
            if cname is None:
                need("compiler")
            counts["@typeInfo(…) -> comptime compiler.typeInfo(…)"] += 1
        elif name == "src" and after < len(m) and m[after] == "(":
            close = match_close(m, after)
            if close < 0 or m[after + 1:close].strip():
                undecided.append((line_of(a), "@src with arguments"))
                continue
            if cname is None and clashes("compiler", a, "@src"):
                continue
            under = re.search(r"\bcomptime\s*$", m[:a]) is not None
            ed.add(a, close + 1, ("" if under else "comptime ") + (cname or "compiler") + ".src")
            if cname is None:
                need("compiler")
            counts["@src() -> comptime compiler.src"] += 1
        else:
            counts["left: @%s" % name] += 1

    # `#[external(` (std's spelling until now).
    for mo in re.finditer(r"#\[\s*(external)\s*\(", m):
        a = mo.start(1)
        if cname is None and clashes("compiler", a, "#[external"):
            continue
        ed.add(a, mo.end(1), (cname or "compiler") + ".external")
        if cname is None:
            need("compiler")
        counts["#[external -> #[compiler.external"] += 1

    new = ed.apply(text)
    if needs:
        new, extra = add_imports(new, [IMPORTS[n][0] for n in needs], key is not None)
        if extra:
            ed.edits.append(extra)
        for n in needs:
            counts["import {%s}" % IMPORTS[n][0]] += 1
    return new, counts, undecided, ed


def add_imports(text, items, in_std):
    """`text` with `items` imported (merged into the first std import, else a new line), and the
    one insertion made as an edit of the text it was given — (offset, offset, inserted) — or
    None when the items were merged into an import on its own line."""
    m = mask(text)
    pat = r"\bimport\s*\{([^}]*)\}\s*;" if in_std else r"\bimport\s*\{([^}]*)\}\s*from\s*\"std\"\s*;"
    std_imports = [mo for mo in re.finditer(pat, text) if m[mo.start()] == "i"]
    if std_imports:
        mo = std_imports[0]
        a, b = mo.start(1), mo.end(1)
        inner = text[a:b]
        if "\n" in inner:
            body = inner.rstrip()
            ind = re.search(r"\n([ \t]*)\S", inner).group(1)
            sep = "" if body.endswith(",") else ","
            ins = sep + "".join("\n" + ind + it + "," for it in items)
            at = a + len(body)
        else:
            body = inner.rstrip().rstrip(",")
            ins = ", " + ", ".join(items)
            at = a + len(body)
        return text[:at] + ins + text[at:], (at, at, ins)
    line = "import {" + ", ".join(items) + "}" + ("" if in_std else ' from "std"') + ";\n"
    imps = list(re.finditer(r"^import\b[^;]*;[ \t]*\n", m, re.M))
    if imps:
        at = imps[-1].end()
        return text[:at] + line + text[at:], (at, at, line)
    at = 0
    for mo in re.finditer(r"[^\n]*\n", text):
        if text[mo.start():mo.end()].lstrip().startswith("//") and mo.start() == at:
            at = mo.end()
        else:
            break
    if at:
        ins = "\n" + line + ("" if text[at:].startswith("\n") else "\n")
        return text[:at] + ins + text[at:], (at, at, ins)
    ins = line + "\n"
    return ins + text, (0, 0, ins)


# ── prose: comments, `////` reference lines and `test "…"` names ─────────────

PROSE_TYPES = {"Result": "Result", "Task": "Async", "Component": "Component", "Iterator": "Iter",
               "Stream": "AsyncIter", "Option": "Option"}
PROSE_RULES = [
    (re.compile(r"#\[@External\.(Beam|Erlang|Node|JavaScript|Wasm|<\w+>)(?:\((.*?)\))?\]"),
     lambda mo: "#[compiler.external(.%s%s)]" % (TARGETS.get(mo.group(1), mo.group(1)),
                                                 "" if mo.group(2) is None else "(%s)" % mo.group(2)),
     "#[@External.<T>(…)]"),
    (re.compile(r"@External\.(Beam|Erlang|Node|JavaScript|Wasm)\b"),
     lambda mo: "compiler.external(.%s)" % TARGETS[mo.group(1)], "@External.<T>"),
    (re.compile(r"@(Result|Task|Component|Iterator|Stream|Option)\b"),
     lambda mo: PROSE_TYPES[mo.group(1)], "@<Type>"),
    (re.compile(r"@(?:print|debug|println)\b"), lambda mo: "terminal.print", "@print"),
    (re.compile(r"@panic\b"), lambda mo: "panic", "@panic"),
    (re.compile(r"@typeInfo\b"), lambda mo: "compiler.typeInfo", "@typeInfo"),
]
TEST_NAME = re.compile(r'^(\s*test\s+")([^"\n]*)(")', re.M)


def prose_text(t, counts):
    for rx, fn, label in PROSE_RULES:
        t, n = rx.subn(fn, t)
        if n:
            counts["prose: " + label] += n
    return t


def rewrite_prose(text):
    """`text` with the old spellings respelled inside comments (`//`, `///`, `////`) and test names."""
    m = mask(text)
    counts = collections.Counter()
    out, pos = [], 0
    for ls in [0] + [i + 1 for i, c in enumerate(text) if c == "\n"]:
        le = text.find("\n", ls)
        le = len(text) if le < 0 else le
        line = text[ls:le]
        k = 0
        cut = None
        while True:
            k = line.find("//", k)
            if k < 0:
                break
            if m[ls + k:ls + k + 2] == "  " and line[:k].count('"') % 2 == 0:
                cut = k
                break
            k += 2
        tn = TEST_NAME.match(line)
        if cut is not None and "@" in line[cut:]:
            new = line[:cut] + prose_text(line[cut:], counts)
        elif tn and "@" in tn.group(2):
            new = tn.group(1) + prose_text(tn.group(2), counts) + line[tn.end(2):]
        else:
            continue
        if new != line:
            out.append(text[pos:ls])
            out.append(new)
            pos = le
    out.append(text[pos:])
    return "".join(out), counts


# ── locations: an original (line, col) to the rewritten text's ─────────────

class LocMap:
    def __init__(self, text, edits):
        self.text = text
        self.starts = [0] + [i + 1 for i, c in enumerate(text) if c == "\n"]
        # Each edit in original offsets; the merged import's insertion is in the text after the
        # site edits, so translate it back to an original offset first.
        site = sorted(e for e in edits[:-1]) if edits and edits[-1][0] == edits[-1][1] and _is_import(edits[-1]) else sorted(edits)
        imp = edits[-1] if site is not edits and len(site) != len(edits) else None
        self.site = site
        self.imp = None
        if imp is not None:
            self.imp = (self._orig_of_shifted(imp[0]), imp[2])
        self.new_text = None

    def _orig_of_shifted(self, q):
        # an offset of the site-edited text back to the original (insertions land after
        # everything before them)
        delta = 0
        for a, b, t in self.site:
            na = a + delta
            if q < na:
                break
            if q < na + len(t):
                return b
            delta += len(t) - (b - a)
        return q - delta

    def offset(self, line, col):
        if line - 1 >= len(self.starts):
            return None
        return self.starts[line - 1] + col - 1

    def new_offset(self, p):
        delta = 0
        q = None
        for a, b, t in self.site:
            if p < a:
                break
            if p < b:
                q = a + delta  # inside a rewritten site: its start
                break
            delta += len(t) - (b - a)
        if q is None:
            q = p + delta
        if self.imp is not None and p >= self.imp[0]:
            q += len(self.imp[1])
        return q

    def map(self, new_text, line, col):
        p = self.offset(line, col)
        if p is None:
            return line, col
        q = self.new_offset(p)
        nl = new_text.count("\n", 0, q) + 1
        ls = new_text.rfind("\n", 0, q) + 1
        return nl, q - ls + 1


def _is_import(e):
    return "import" in e[2] or e[2].startswith(",") or e[2].startswith(", ")


def cell_root(path):
    d = os.path.dirname(os.path.abspath(path))
    while d and d != "/":
        if os.path.isfile(os.path.join(d, "botopink.json")) and os.path.isdir(os.path.join(d, "snapshot")):
            return d
        if os.path.basename(d) == "modules":
            return None
        d = os.path.dirname(d)
    return None


LOC = re.compile(r"^(at|from) (\S+?):(\d+):(\d+)(.*)$")


def move_snapshot_locations(path, text, new, edits):
    root = cell_root(path)
    if root is None:
        return 0
    rel = os.path.relpath(os.path.abspath(path), root).replace(os.sep, "/")
    lm = LocMap(text, edits)
    moved = 0
    snap_dir = os.path.join(root, "snapshot")
    for d, _, fs in os.walk(snap_dir):
        for f in fs:
            if not f.endswith(".snap"):
                continue
            sp = os.path.join(d, f)
            with open(sp, encoding="utf-8") as fh:
                lines = fh.read().split("\n")
            changed = False
            same_module = rel == "src/" + os.path.relpath(sp, d).replace(".snap", ".bp") or \
                rel == "src/" + f.replace(".snap", ".bp")
            for i, ln in enumerate(lines):
                mo = LOC.match(ln)
                if mo and mo.group(2) == rel:
                    nl, nc = lm.map(new, int(mo.group(3)), int(mo.group(4)))
                    if (nl, nc) != (int(mo.group(3)), int(mo.group(4))):
                        lines[i] = "%s %s:%d:%d%s" % (mo.group(1), rel, nl, nc, mo.group(5))
                        changed = True
                        moved += 1
                    continue
                if not ln.startswith(("refused ", "stderr ", "label ")):
                    continue
                # A place written inside the text: `src/main.bp:7:14`, and in the module's own
                # snapshot `at 7:18` / `line 9`.
                def full(x):
                    nl, nc = lm.map(new, int(x.group(1)), int(x.group(2)))
                    return "%s:%d:%d" % (rel, nl, nc)
                out = re.sub(re.escape(rel) + r":(\d+):(\d+)", full, ln)
                if same_module:
                    out = re.sub(r"\bat (\d+):(\d+)\b", lambda x: "at %d:%d" % lm.map(new, int(x.group(1)), int(x.group(2))), out)
                    out = re.sub(r"\bline (\d+)\b", lambda x: "line %d" % lm.map(new, int(x.group(1)), 1)[0], out)
                if out != ln:
                    lines[i] = out
                    changed = True
                    moved += 1
            if changed:
                with open(sp, "w", encoding="utf-8") as fh:
                    fh.write("\n".join(lines))
    return moved


# ── `.zig` test sources: the `\\` blocks ────────────────────────────────────

ZIG_LINE = re.compile(r"^([ \t]*\\\\)(.*)$")


def rewrite_zig(text):
    lines = text.split("\n")
    out, i = [], 0
    counts = collections.Counter()
    undecided = []
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
        if "@" in src:
            new, c, und, _ = rewrite_block(src)
            counts.update(c)
            undecided += [(i + l, w) for l, w in und]
            if new != src:
                block = [prefix + ln for ln in new.split("\n")]
        out.extend(block)
        i = j
    return "\n".join(out), counts, undecided


def rewrite_block(src):
    """A `\\\\` block: the site rewrites, and the import written as its last line."""
    new, counts, und, ed = rewrite(src, None)
    if new == src:
        return new, counts, und, ed
    # Undo the merged / inserted import and write it last, so no line moves.
    sites = Edits()
    sites.edits = [e for e in ed.edits if not _is_import(e)]
    body = sites.apply(src)
    if body == new:
        return new, counts, und, ed
    items = [IMPORTS[k][0] for k in ("print", "panic", "compiler")
             if any(r == "import {%s}" % IMPORTS[k][0] for r in counts)]
    if not items:
        return body, counts, und, ed
    # A blank line before it, as the formatter writes one between declarations.
    sep = "\n" if body.endswith("\n") else "\n\n"
    return body + sep + "import {" + ", ".join(items) + '} from "std";', counts, und, ed


def files_under(paths, ext):
    for root in paths:
        if os.path.isfile(root):
            yield root
            continue
        for d, dirs, fs in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
            for f in sorted(fs):
                path = os.path.join(d, f)
                if f.endswith(ext) and not path.endswith(SKIP_FILES) \
                        and not any(c in path.replace(os.sep, "/") for c in SKIP_CELLS):
                    yield path


def main(argv):
    check = "--check" in argv
    zig = "--zig" in argv
    snaps = "--snapshots" in argv
    paths = [a for a in argv if not a.startswith("--")]
    if not paths:
        print(__doc__)
        return 2
    total = collections.Counter()
    changed = undecided = moved = 0
    for path in files_under(paths, ".zig" if zig else ".bp"):
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        if zig:
            new, counts, und = rewrite_zig(text)
            edits = None
        else:
            new, counts, und, ed = rewrite(text, std_key(path))
            edits = ed.edits
            code_new = new
            new, pc = rewrite_prose(new)  # same lines, so the snapshot locations follow code_new
            counts.update(pc)
        for line, what in und:
            print("UNDECIDED %s:%d %s" % (path, line, what))
            undecided += 1
        total.update(counts)
        if new == text:
            continue
        changed += 1
        if check:
            print("WOULD CHANGE %s" % path)
            continue
        if snaps and edits is not None:
            moved += move_snapshot_locations(path, text, code_new, edits)
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(new)
    for rule, n in sorted(total.items()):
        print("%6d  %s" % (n, rule))
    print("%6d  files %s" % (changed, "to change" if check else "changed"))
    if snaps:
        print("%6d  snapshot locations moved" % moved)
    print("%6d  undecided sites" % undecided)
    return 1 if check and changed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
