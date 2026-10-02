#!/usr/bin/env python3
"""Decision 206 codemod: an import of a module of the importing package names it
inside the braces, with no `from`.

    import {area, perimeter as p} from "geometry";   ->  import {geometry.area, geometry.perimeter as p};
    import {name, x: {y}} from "shapes.circle";      ->  import {shapes.circle.name, shapes.circle.x.y};

`from "<name>"` names a package only — std, a bundled package or a declared
dependency — so every import whose `from` named a module of its own package is
rewritten to the brace form, every leaf behind its dotted path: the spelling
`botopink format` prints (the formatter flattens a group, so a group is never
the canonical form). The layout between the items — a list written over
several lines — is kept; a brace list that carries a comment is kept verbatim
inside one group per path segment instead. Afterwards the formatter is run
over every file this changed that was canonical before, so `botopink format
--check` stays green.

Which module an import named is answered the way the compiler answered it
before decision 206: the source's path among the package's modules (the
`src/` tree, and the flat `test/` suite for a test file), else the one module
whose last segment the source spells. It is the package's own module when that
module exports every item the import names (a decorator-emitted name counts as
a miss); otherwise a source whose first segment is a package — bundled or
declared — names that package and keeps its `from` (`rakun-app`'s module
`actions` importing the bundled `actions`), and anything else is UNDECIDED.
A package whose directory holds a `*.expect` naming `module-import-with-from`
(the language suite's cell pinning the refusal) is left alone.

    scripts/codemod-import-without-from.py [--write] [--format BOTOPINK] ROOT...

Without `--write` it only reports. It prints one line per rewritten import and
a final tally; an import it cannot decide is printed as `UNDECIDED` and left
untouched, and the run exits 1 when there is one.
"""
import json
import os
import re
import subprocess
import sys

BUNDLED = {"std", "routing", "http", "actions", "validation", "log"}
SKIP_DIRS = {".botopinkbuild", "node_modules", "out", "zig-out", ".zig-cache"}


# ── packages and their modules ──────────────────────────────────────────────

def load_manifest(path):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return None


SOURCE_EXTS = (".bp", ".bp.fixture")


def is_fixture_project(d):
    """A test's fixture project: `src/` holds `*.bp.fixture` sources and the
    manifest is written when the test runs (rakun's `test/fixtures/<name>/`)."""
    src = os.path.join(d, "src")
    return os.path.isdir(src) and any(f.endswith(".bp.fixture") for f in os.listdir(src))


def find_manifests(root):
    out = []
    for d, dirs, files in os.walk(root):
        dirs[:] = sorted(x for x in dirs if not x.startswith(".") and x not in SKIP_DIRS)
        if "botopink.json" in files or is_fixture_project(d):
            out.append(d)
    return out


def module_path_of(rel):
    """`shapes/circle.bp` -> `shapes/circle`; `shapes/mod.bp` -> `shapes`."""
    if rel.endswith(".fixture"):
        rel = rel[: -len(".fixture")]
    for ext in (".d.bp", ".bp"):
        if rel.endswith(ext):
            rel = rel[: -len(ext)]
            break
    if rel.endswith("/mod"):
        rel = rel[: -len("/mod")]
    return rel


class Package:
    def __init__(self, directory, manifest, nested):
        self.dir = directory
        self.name = manifest.get("name", "")
        deps = manifest.get("dependencies") or {}
        self.deps = set(deps.keys()) if isinstance(deps, dict) else set(deps)
        src = (manifest.get("src") or "src/").rstrip("/")
        if src.startswith("./") and len(src) > 2:
            src = src[2:]
        self.src = "." if src in ("", ".") else src
        self.nested = nested  # absolute dirs of nested packages (not ours)
        self.src_modules = {}  # module path -> file
        self.test_modules = {}
        self.files = []  # every .bp file of this package (abs)
        # The language suite's cell that pins the refusal of the old form
        # (a `<target>.expect` naming `module-import-with-from`) keeps it.
        self.pins_refusal = any(
            f.endswith(".expect") and "module-import-with-from" in open(os.path.join(directory, f), encoding="utf-8").read()
            for f in os.listdir(directory)
        )
        self._collect()

    def _walk(self, base):
        if not os.path.isdir(base):
            return
        for d, dirs, files in os.walk(base):
            keep = []
            for x in sorted(dirs):
                full = os.path.join(d, x)
                if x.startswith(".") or x in SKIP_DIRS or full in self.nested:
                    continue
                keep.append(x)
            dirs[:] = keep
            for f in sorted(files):
                if f.endswith(SOURCE_EXTS):
                    yield os.path.join(d, f)

    def _collect(self):
        src_dir = os.path.normpath(os.path.join(self.dir, self.src))
        test_dir = os.path.join(self.dir, "test")
        seen = set()
        for f in self._walk(src_dir):
            rel = os.path.relpath(f, src_dir)
            if self.src == "." and (rel.startswith("test/") or rel == "test"):
                continue
            self.src_modules[module_path_of(rel)] = f
            seen.add(f)
        for f in self._walk(test_dir):
            if f in seen:
                continue
            self.test_modules[module_path_of(os.path.relpath(f, test_dir))] = f
            seen.add(f)
        for f in self._walk(self.dir):
            self.files.append(f)

    def own_modules(self, file):
        """The modules an import in `file` may name as its own package's: the
        `src/` tree, plus the flat `test/` suite for a test file."""
        mods = dict(self.src_modules)
        if file in self.test_modules.values():
            mods.update(self.test_modules)
        return mods

    def module_of(self, file):
        for table in (self.src_modules, self.test_modules):
            for k, v in table.items():
                if v == file:
                    return k
        return None


def discover(roots):
    dirs = []
    for r in roots:
        dirs.extend(find_manifests(os.path.abspath(r)))
    dirs = sorted(set(dirs))
    pkgs = []
    for d in dirs:
        m = {} if is_fixture_project(d) else load_manifest(os.path.join(d, "botopink.json"))
        if m is None or "workspaces" in m:
            continue  # not a package: a workspace compiles nothing
        nested = {x for x in dirs if x != d and x.startswith(d + os.sep)}
        pkgs.append(Package(d, m, nested))
    return pkgs


# ── lexing just enough of botopink ──────────────────────────────────────────

def blank_comments_and_strings(text):
    """`text` with every comment and string literal's content replaced by
    spaces (newlines kept), so offsets stay valid and a `import`/`{`/`}` inside
    one is never read."""
    out = list(text)
    i, n = 0, len(text)
    while i < n:
        c = text[i]
        if text.startswith("//", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                out[k] = " "
            i = j
        elif text.startswith('"""', i):
            j = text.find('"""', i + 3)
            j = n if j < 0 else j + 3
            for k in range(i + 3, max(i + 3, j - 3)):
                if out[k] != "\n":
                    out[k] = " "
            i = j
        elif text.startswith("\\\\", i):
            j = text.find("\n", i)
            j = n if j < 0 else j
            for k in range(i, j):
                out[k] = " "
            i = j
        elif c == '"':
            j = i + 1
            while j < n and text[j] != '"' and text[j] != "\n":
                j += 2 if text[j] == "\\" else 1
            for k in range(i + 1, min(j, n)):
                out[k] = " "
            i = j + 1
        else:
            i += 1
    return "".join(out)


IMPORT_RE = re.compile(r"^import\s*\{", re.M)
FROM_RE = re.compile(r'\s*from\s*"([^"]*)"\s*;')
EXPORT_RE = re.compile(
    r"^[ \t]*(?:#\[[^\n]*\][ \t]*\n[ \t]*)*pub\s+(?:default\s+)?(?:declare\s+)?"
    r"(?:fn|val|var|type|behavior|mod|implement|extend)\s+([A-Za-z_][A-Za-z0-9_]*)",
    re.M,
)


def exports_of(path, cache={}):
    if path not in cache:
        try:
            with open(path, encoding="utf-8") as f:
                text = blank_comments_and_strings(f.read())
        except OSError:
            text = ""
        cache[path] = set(EXPORT_RE.findall(text))
    return cache[path]


def split_items(inner_blank):
    """Top-level items of a brace list (on the comment-blanked text): a list
    of (start, end) offsets into it."""
    items, depth, start = [], 0, 0
    for i, c in enumerate(inner_blank):
        if c == "{":
            depth += 1
        elif c == "}":
            depth -= 1
        elif c == "," and depth == 0:
            items.append((start, i))
            start = i + 1
    items.append((start, len(inner_blank)))
    return [(a, b) for a, b in items if inner_blank[a:b].strip()]


ITEM_LEAF_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)((?:\s*\.\s*[A-Za-z_][A-Za-z0-9_]*)*)\s*(\*)?\s*(?:as\s+[A-Za-z_][A-Za-z0-9_]*)?\s*$")
ITEM_GROUP_RE = re.compile(r"^\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*\{", re.S)


def item_heads(inner_blank):
    """The first segment of every top-level item, and whether every item is a
    plain dotted leaf (no group)."""
    heads, all_leaves = [], True
    for a, b in split_items(inner_blank):
        t = inner_blank[a:b]
        m = ITEM_LEAF_RE.match(t)
        if m:
            heads.append(m.group(1))
            continue
        g = ITEM_GROUP_RE.match(t)
        if g:
            heads.append(g.group(1))
            all_leaves = False
            continue
        return None, False
    return heads, all_leaves


# ── deciding and rewriting ──────────────────────────────────────────────────

def first_segment(src):
    return re.split(r"[./]", src, maxsplit=1)[0]


def own_target(pkg, file, src, heads):
    """The module of `pkg` this `from "<src>"` named, or None for a package.
    Returns (path, None) or (None, reason) when undecided."""
    own = pkg.own_modules(file)
    slashed = src.replace(".", "/")
    cands = []
    if slashed in own:
        cands = [slashed]
    elif "/" not in slashed:
        cands = [p for p in own if p.rsplit("/", 1)[-1] == slashed]
    me = pkg.module_of(file)
    cands = [c for c in cands if c != me]
    if not cands:
        return None, None
    if len(cands) > 1:
        return None, "names several modules of the package by their last segment: " + ", ".join(sorted(cands))
    path = cands[0]
    exp = set(exports_of(own[path]))
    # A leaf that is a submodule of the target (the namespace form).
    subs = {p[len(path) + 1 :].split("/")[0] for p in own if p.startswith(path + "/")}
    hits = [h for h in heads if h in exp or h in subs]
    if len(hits) == len(heads):
        return path, None
    if first_segment(src) in BUNDLED or first_segment(src) in pkg.deps:
        return None, None  # a package named like a module of this one
    if not hits:
        return None, "names module `%s`, which exports none of %s" % (path, ", ".join(heads))
    return None, "names module `%s`, which exports only %s of %s" % (path, ", ".join(hits), ", ".join(heads))


def flatten(inner_blank, prefix):
    """Every leaf of a brace list as its dotted path under `prefix` — the
    spelling `botopink format` prints (a group is flattened: `x: {a, b}` is
    `x.a, x.b`). None when an item is not read."""
    out = []
    for a, b in split_items(inner_blank):
        t = inner_blank[a:b]
        m = ITEM_LEAF_RE.match(t)
        if m:
            out.append(prefix + " ".join(t.split()).replace(" .", ".").replace(". ", "."))
            continue
        g = ITEM_GROUP_RE.match(t)
        if not g:
            return None
        body = t[g.end() : t.rindex("}")]
        sub = flatten(body, prefix + g.group(1) + ".")
        if sub is None:
            return None
        out.extend(sub)
    return out


def rewrite_inner(path, inner, inner_blank, all_leaves):
    """The brace list with every item under the module's path, in place: each
    item becomes its leaves behind the dotted path (a group flattened, as
    `botopink format` prints it), and the text between items — the commas, the
    line breaks and the indentation of a list written over several lines — is
    kept. A list that carries a comment is kept verbatim inside one group per
    path segment (`a: {b: {<inner>}}`) instead."""
    segs = path.split("/")
    if "//" not in inner:
        prefix = ".".join(segs) + "."
        out, at = [], 0
        for a, b in split_items(inner_blank):
            t = inner_blank[a:b]
            lead = len(t) - len(t.lstrip())
            trail = len(t) - len(t.rstrip())
            leaves = flatten(t, prefix)
            if leaves is None:
                break
            out.append(inner[at : a + lead])
            out.append(", ".join(leaves))
            at = b - trail
        else:
            out.append(inner[at:])
            return "".join(out)
    nest = inner if "\n" in inner else inner.strip()
    for seg in reversed(segs):
        nest = "%s: {%s}" % (seg, nest)
    return nest


def process_file(pkg, file, write, report):
    with open(file, encoding="utf-8") as f:
        text = f.read()
    blank = blank_comments_and_strings(text)
    edits = []
    undecided = []
    for m in IMPORT_RE.finditer(blank):
        open_at = m.end() - 1
        depth, i = 0, open_at
        while i < len(blank):
            if blank[i] == "{":
                depth += 1
            elif blank[i] == "}":
                depth -= 1
                if depth == 0:
                    break
            i += 1
        close_at = i
        fm = FROM_RE.match(text, close_at + 1)
        if not fm or not FROM_RE.match(blank, close_at + 1):
            continue
        src = fm.group(1)
        inner = text[open_at + 1 : close_at]
        inner_blank = blank[open_at + 1 : close_at]
        heads, all_leaves = item_heads(inner_blank)
        line = text.count("\n", 0, m.start()) + 1
        where = "%s:%d" % (file, line)
        if heads is None:
            undecided.append((where, src, "an item the codemod does not read"))
            continue
        path, why = own_target(pkg, file, src, heads)
        if why:
            undecided.append((where, src, why))
            continue
        if path is None:
            continue
        new_inner = rewrite_inner(path, inner, inner_blank, all_leaves)
        new = "import {%s};" % new_inner
        edits.append((m.start(), fm.end(), new, where, src))
    for e in undecided:
        report.append("UNDECIDED %s  from \"%s\": %s" % e)
    if not edits:
        return 0, len(undecided)
    out = text
    for start, end, new, where, src in reversed(edits):
        report.append("rewrite   %s  from \"%s\" -> %s" % (where, src, " ".join(new.split())))
        out = out[:start] + new + out[end:]
    if write:
        with open(file, "w", encoding="utf-8") as f:
            f.write(out)
    return len(edits), len(undecided)


def is_canonical(botopink, file):
    if not botopink:
        return False
    r = subprocess.run([botopink, "format", "--check", file], capture_output=True)
    return r.returncode == 0


def main(argv):
    write = "--write" in argv
    botopink = None
    roots = []
    it = iter(argv)
    for a in it:
        if a == "--write":
            continue
        if a == "--format":
            botopink = next(it)
            continue
        roots.append(a)
    if not roots:
        print(__doc__, file=sys.stderr)
        return 2
    pkgs = discover(roots)
    owned = {}
    for p in pkgs:
        for f in p.files:
            owned[f] = p
    report, files_changed, lines, undecided = [], [], 0, 0
    for f in sorted(owned):
        pkg = owned[f]
        if pkg.pins_refusal:
            continue
        canonical = write and is_canonical(botopink, f)
        n, u = process_file(pkg, f, write, report)
        undecided += u
        if n:
            files_changed.append(f)
            lines += n
            if write and canonical:
                subprocess.run([botopink, "format", f], capture_output=True, check=True)
    for r in report:
        print(r)
    print("rewrote %d import(s) in %d file(s); %d undecided" % (lines, len(files_changed), undecided))
    return 1 if undecided else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
