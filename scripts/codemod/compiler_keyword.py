#!/usr/bin/env python3
"""144 B-136's codemod: decisions 575 (4), (5), 576, 577, 578, 579 — `@Expr`, `@Decl`
and `@ExprCustom` go; a build-time body talks to the compiler through
`compiler`, std's value imported (579); a parameter says how its argument arrives (`comptime` /
`expr`); `type T` becomes `type<T>`.

    comptime x: @Expr<T>          ->  comptime x: T     (the body reads `x.value`, and otherwise only
                                                         fails at `x`; each read dropped)
                                  ->  expr x: T         (anything else)
    x.text()                      ->  compiler.text(x)
    x.fail(m)                     ->  compiler.fail(m, at: x)
    x.failAt(span, m)             ->  compiler.fail(m, at: x, span: span)
    x.<m>(…)                      ->  compiler.<m>(x, …)     (the template model: source,
                                                              context, lookup, bindings; `x.parts()`
                                                              is UNDECIDED, 577 (5))
    x.<m>(…)                      ->  compiler.<m>(…)        (build, note, tagDecl, annotate: 576 (2))
    @expr(v)                      ->  v
    -> @Expr<T> / -> @ExprCustom<T>   ->  -> T  (578; the template's first parameter, after
                                          a `self` receiver, is `expr q: string`, its value
                                          reads `compiler.text(q)`)
    return x.custom(ast, code);   ->  compiler.custom(ast); return code;
    comptime d: @Decl             ->  expr d: unknown
    comptime d: @Decl<T>          ->  expr d: T
    d.name                        ->  compiler.name(d)!
    d.<r> / d.<r>(…)              ->  compiler.<r>(d, …)     (kind, module → moduleOf, attr,
                                                              component, hooks, fields, methods,
                                                              params, returnType, owner,
                                                              annotations, variants)
    d.meta(T) / d.metaAll(T)      ->  compiler.meta<T>(d) / compiler.metaAll<T>(d)
    d.setMeta(v) / addMeta / addMember / addType / wrapWith(…)  ->  compiler.<m>(…)
    d.addType(name, src)          ->  compiler.addType(name, compiler.buildType(src))   (578 (3))
    (the handle rules also take a local `val x = q.lookup / tagDecl / annotate(…)`
    and `val x = d.owner…`, and `d.owner!.<r>`; the elements of `methods`,
    `params`, `annotations`, `hooks`, `fields` are records and stay)
    f: @Expr<T>  (a record field) ->  f: T
    type T  (in a type)           ->  type<T>
    type    (bare, in a type)     ->  anytype   (`type<T>`, `type(`, `type {` stay)

Left alone and counted: `Declared<…>`, the string form `setMeta("key", value)`,
a `.value` read on an `expr` parameter, a `custom(…)` call that is not a whole
`return` statement, any other member read on a handle. Comments and string
contents are never rewritten (a `${…}` hole is code).

    scripts/codemod/compiler_keyword.py [--check] [--measure] [--format BOTOPINK] [--imports] PATH...

Without a flag it rewrites every `.bp` file under each PATH in place and prints
the per-rule counts. `--check` writes nothing and exits 1 when a file would
change (idempotence: a second run over its own output changes nothing).
`--format BOTOPINK` runs that compiler's formatter over each file it changed that
was canonical before, through today's parser (`to_old` / `to_new` below); a file
the formatter cannot read keeps the codemod's layout and is named. The template
texts `@`…`` (577), which today's formatter cannot read, are written after it ran.
`--imports` adds decision 579's `import {compiler}` to a file reading `compiler.`, and
decision 576 (13)'s `import {compiler.<Name>}` for the types of
`compiler.bp` a file names (off by default: they stay prelude names until B-136's
removal piece, which runs it).
`--measure` prints, for the tree as it is, the reads with no 576 spelling and
the open-question sites (`Declared<`, string `setMeta`, `addMeta`, `wrapWith`).
"""
import collections
import os
import re
import sys

# B-136's compiler side writes these by hand (the builtins' declarations).
SKIP_FILES = ("std/src/builtins.d.bp", "std/src/builtins_fns.d.bp", "std/src/compiler.bp")
# B-136's refusal cells whose sources spell what the codemod removes, on purpose.
# 579's cells of a file without the import — `compiler` unbound, or an ordinary
# local — which `--imports` would otherwise give one.
SKIP_CELLS = ("conformance/modules/removed_type_bare_param/", "conformance/modules/expr_param_method/",
              "conformance/modules/compiler_import_missing/", "conformance/modules/compiler_ordinary_name/")
# Refusal cells of 577 (3): their template call `name("lit")` / `#[name("lit")]` is the refused shape.
KEEP_TEMPLATE_CALLS = ("conformance/modules/expr_call_outside_expr/",
                       "conformance/modules/template_annotation_call_form/")
SKIP_DIRS = {".botopinkbuild", "node_modules", "out", "zig-out", ".zig-cache", ".git", "snapshot"}

TEMPLATE_MODEL = ("source", "context", "lookup", "bindings")
# 576 (2): these do not read the expr they were called on.
TEMPLATE_MODEL_NO_EXPR = ("build", "note", "tagDecl", "annotate")
# A local bound from one of these holds a declaration handle.
HANDLE_SOURCES = ("lookup", "tagDecl", "annotate")
DECL_READS = ("kind", "moduleOf", "attr", "component", "hooks", "fields", "methods", "params",
              "returnType", "owner", "annotations", "variants")
DECL_RENAMED = {"module": "moduleOf"}
DECL_TYPED_READS = ("meta", "metaAll")
DECL_OUTPUTS = ("setMeta", "addMeta", "addMember", "addType", "wrapWith")
# Members decisions 575 (3) and 576 (2), (3), (4), (8), (9) spell on `Compiler`.
SPELLED = {"src", "module", "package", "isStd", "fail", "compile", "setMeta", "addMember", "addType",
           "implement", "setBuiltin", "embed", "catalogue", "record", "fields", "optional", "required",
           "typeInfo", "text", "name", "parts", "source", "context", "lookup", "bindings", "build", "note",
           "tagDecl", "annotate", "kind", "moduleOf", "meta", "metaAll", "attr", "component", "custom",
           "hooks", "methods", "params", "returnType", "owner", "annotations", "variants", "addMeta",
           "wrapWith"}

IDENT = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


# ── masking: comments and string contents blanked, `${…}` holes kept ────────

def mask(text):
    out = list(text)
    n = len(text)

    def blank(a, b):
        for k in range(a, b):
            if out[k] != "\n":
                out[k] = " "

    def code(i, in_hole):
        depth = 0
        while i < n:
            c = text[i]
            if c == "/" and text.startswith("//", i):
                e = text.find("\n", i)
                e = n if e < 0 else e
                blank(i, e)
                i = e
            elif c == "\\" and text.startswith("\\\\", i):
                e = text.find("\n", i)
                e = n if e < 0 else e
                blank(i + 2, e)
                i = e
            elif c == '"':
                if text.startswith('"""', i):
                    i = string(i + 3, '"""')
                else:
                    i = string(i + 1, '"')
            elif c == "'":
                j = i + 1
                while j < n and text[j] not in "'\n":
                    j += 2 if text[j] == "\\" else 1
                blank(i + 1, min(j, n))
                i = j + 1
            elif c == "{":
                depth += 1
                i += 1
            elif c == "}":
                if in_hole and depth == 0:
                    return i
                depth -= 1
                i += 1
            else:
                i += 1
        return n

    def string(i, close):
        while i < n:
            if text.startswith(close, i):
                return i + len(close)
            if text[i] == "\\":
                blank(i, min(i + 2, n))
                i += 2
            elif text.startswith("${", i):
                i = code(i + 2, True) + 1
            else:
                blank(i, i + 1)
                i += 1
        return n

    code(0, False)
    return "".join(out)


# ── bracket helpers over the mask ────────────────────────────────────────────

PAIRS = {"(": ")", "[": "]", "{": "}", "<": ">"}


def match_close(m, i):
    """Index of the bracket closing the one at `i` (angles aware of `->`)."""
    stack = [PAIRS[m[i]]]
    j = i + 1
    angle = m[i] == "<"
    while j < len(m):
        c = m[j]
        if c == "-" and m.startswith("->", j):
            j += 2
            continue
        if c in "([{" or (c == "<" and angle):
            stack.append(PAIRS[c])
        elif c in ")]}" or (c == ">" and angle):
            if stack[-1] != c:
                if c == ">":
                    j += 1
                    continue
                return -1
            stack.pop()
            if not stack:
                return j
        j += 1
    return -1


def split_top(m, a, b, sep=","):
    """[(start, end)] of the top-level `sep`-separated parts of m[a:b]."""
    parts, depth, start, j = [], 0, a, a
    while j < b:
        c = m[j]
        if c == "-" and m.startswith("->", j):
            j += 2
            continue
        if c in "([{<":
            depth += 1
        elif c in ")]}>":
            depth -= 1
        elif c == sep and depth == 0:
            parts.append((start, j))
            start = j + 1
        j += 1
    if m[start:b].strip():
        parts.append((start, b))
    return parts


def strip_range(m, a, b):
    while a < b and m[a].isspace():
        a += 1
    while b > a and m[b - 1].isspace():
        b -= 1
    return a, b


def skip_ws(m, i):
    while i < len(m) and m[i].isspace():
        i += 1
    return i


# ── the parse: functions, their parameters and bodies ───────────────────────

class Fn:
    def __init__(self):
        self.params = []      # (start, end) of each parameter in the original
        self.ret = None       # (start, end) of the return type
        self.body = None      # (start, end) inside the braces
        self.name = None      # the declared name, None for a lambda or a type
        self.start = 0        # the `fn` keyword


def functions(m):
    fns = []
    for mo in re.finditer(r"\bfn\b", m):
        i = skip_ws(m, mo.end())
        nm = IDENT.match(m, i)
        if nm:
            i = skip_ws(m, nm.end())
        if i < len(m) and m[i] == "<":
            c = match_close(m, i)
            if c < 0:
                continue
            i = skip_ws(m, c + 1)
        if i >= len(m) or m[i] != "(":
            continue
        close = match_close(m, i)
        if close < 0:
            continue
        f = Fn()
        f.name = nm.group(0) if nm else None
        f.start = mo.start()
        f.params = [strip_range(m, a, b) for a, b in split_top(m, i + 1, close)]
        j = skip_ws(m, close + 1)
        if m.startswith("->", j):
            k = skip_ws(m, j + 2)
            r = k
            depth = 0
            while r < len(m):
                c = m[r]
                if c == "-" and m.startswith("->", r):
                    r += 2
                    continue
                if c in "(<[":
                    depth += 1
                elif c in ")>]":
                    if depth == 0:
                        break
                    depth -= 1
                elif c in "{;,=" and depth == 0:
                    break
                r += 1
            f.ret = strip_range(m, k, r)
            j = skip_ws(m, r)
        if j < len(m) and m[j] == "{":
            bc = match_close(m, j)
            if bc > 0:
                f.body = (j + 1, bc)
        fns.append(f)
    return fns


PARAM = re.compile(r"((?:#\[[^\]]*\]\s*)*)(?:(comptime|expr)\s+)?(\.\.)?([A-Za-z_]\w*)\s*:\s*")


def type_at(m, i, bare_decl=False):
    """(kind, inner_start, inner_end, end) of an `@Expr<…>` / `@ExprCustom<…>` /
    `@Decl[<…>]` type at `i` (`Decl[<…>]` too with `bare_decl`), or None."""
    mo = re.compile(r"@(ExprCustom|Expr|Decl)\b").match(m, i)
    if not mo and bare_decl:
        mo = re.compile(r"(Decl)\b").match(m, i)
    if not mo:
        return None
    kind = mo.group(1)
    j = mo.end()
    if j < len(m) and m[j] == "<":
        c = match_close(m, j)
        if c < 0:
            return None
        return kind, j + 1, c, c + 1
    if kind == "Decl":
        return kind, None, None, j
    return None


# ── the template text (decision 577) ─────────────────────────────────────────

ESCAPES = {"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"', "0": "\0", "$": "$"}


def string_lit(text, i):
    """(end, raw) of the string literal at `i` (a quoted or a triple-quoted one), its escapes
    resolved and its `${…}` holes kept as written; None when it is not one."""
    n = len(text)
    close = '"""' if text.startswith('"""', i) else '"'
    j = i + len(close)
    out = []
    while j < n:
        if text.startswith(close, j):
            return j + len(close), "".join(out)
        c = text[j]
        if c == "\\":
            if j + 1 >= n:
                return None
            k = text[j + 1]
            if k == "u":
                mo = re.compile(r"u\{([0-9a-fA-F]+)\}").match(text, j + 1)
                if not mo:
                    return None
                out.append(chr(int(mo.group(1), 16)))
                j = mo.end()
                continue
            if k not in ESCAPES:
                return None
            out.append(ESCAPES[k])
            j += 2
        elif text.startswith("${", j):
            depth, k = 0, j + 1
            while k < n:
                if text[k] == "{":
                    depth += 1
                elif text[k] == "}":
                    depth -= 1
                    if depth == 0:
                        break
                elif text[k] == '"':
                    k += 1
                    while k < n and text[k] != '"':
                        k += 2 if text[k] == "\\" else 1
                k += 1
            if k >= n:
                return None
            out.append(text[j:k + 1])
            j = k + 1
        elif c == "\n" and close == '"':
            return None
        else:
            out.append(c)
            j += 1
    return None


def template_text(raw):
    """`@`…`` holding `raw` (a backtick written backslash-backtick)."""
    return "@`" + raw.replace("`", "\\`") + "`"


TEMPLATE_TEXT_PARAM = re.compile(r"expr\s+\w+\s*:\s*string")


def template_param_index(text, m, f):
    """578 (1): the index of a function's template text parameter `expr q:
    string` — its first, after an `expr self: R` receiver — or None."""
    ps = [text[a:b].strip() for a, b in f.params]
    i = 1 if ps and re.match(r"expr\s+self\s*:", ps[0]) else 0
    if i < len(ps) and TEMPLATE_TEXT_PARAM.fullmatch(ps[i]):
        return i
    return None


def template_decls(text):
    """[(name, line)] of every template (578 (1)) declared in `text` as the
    codemod writes it."""
    m = mask(text)
    return [(f.name, text.count("\n", 0, f.start) + 1) for f in functions(m)
            if f.name and template_param_index(text, m, f) is not None]


def default_template(text):
    """True when `text` declares a `default fn` template — the template its
    package's default import names (`import badges from "badges"`)."""
    m = mask(text)
    return any(f.name and template_param_index(text, m, f) is not None
               and re.search(r"\bdefault\s+$", m[max(0, f.start - 20):f.start]) for f in functions(m))


def default_import_aliases(text, packages):
    """The names `text` binds by a default import of one of `packages`."""
    m = mask(text)
    out = set()
    for mo in re.finditer(r"\bimport\s+([A-Za-z_]\w*)\s*(?:,\s*\{[^}]*\})?\s*from\s*\"([^\"]+)\"", text):
        if m[mo.start()] == "i" and mo.group(2) in packages:
            out.add(mo.group(1))
    return out


def package_of_dep(path):
    """`<pkg>` of a file under `…/deps/<pkg>/…`, else None."""
    parts = os.path.abspath(path).replace(os.sep, "/").split("/")
    return parts[parts.index("deps") + 1] if "deps" in parts[:-1] else None


def old_template_decls(text):
    """[(name, line)] of every function declared `-> @Expr<…>` / `-> @ExprCustom<…>`."""
    m = mask(text)
    return [(f.name, text.count("\n", 0, f.start) + 1) for f in functions(m)
            if f.name and f.ret and re.match(r"(@Expr<|@ExprCustom<)", m[f.ret[0]:f.ret[1]])]


# ── the imports of compiler.bp's types (decision 576 (13)) ───────────────────

COMPILER_TYPES = ("Span", "Part", "Source", "ExprContext", "CustomNode", "DeclKind", "HookNode", "Field",
                  "Method", "Param", "DeclAnnotation")


def add_compiler_imports(text, in_std):
    """`text` with `import {compiler.<Name>…}` for each of `COMPILER_TYPES` it names
    in a type or value position (merged into the first `from "std"` import; in
    std itself the bare `import {…};`), and the names added."""
    m = mask(text)
    imported = set(re.findall(r"\bcompiler\.(\w+)", " ".join(
        mo.group(0) for mo in re.finditer(r"\bimport\s*\{[^}]*\}", m))))
    other = set()
    for mo in re.finditer(r"\bimport\s*\{([^}]*)\}", m):
        for item in mo.group(1).split(","):
            item = item.strip()
            al = re.search(r"\bas\s+(\w+)$", item)
            last = al.group(1) if al else item.split(".")[-1]
            if not item.startswith("compiler."):
                other.add(last)
    own = set(re.findall(r"\b(?:type|behavior|val|var|fn)\s+(\w+)", m))
    names = []
    for n in COMPILER_TYPES:
        if n in imported or n in other or n in own:
            continue
        for mo in re.finditer(r"(?<![\w.@])" + n + r"(?!\w)", m):
            k = skip_ws(m, mo.end())
            if k < len(m) and m[k] == ":" and not m.startswith("::", k):
                continue  # a label
            names.append(n)
            break
    # Decision 579 — `compiler` is std's value, imported: a file reading
    # `compiler.` outside its imports gets `import {compiler}`.
    outside = re.sub(r"\bimport\s*\{[^}]*\}[^;]*;", "", m)
    has_value = any(re.fullmatch(r"compiler(\s+as\s+\w+)?", item.strip())
                    for mo in re.finditer(r"\bimport\s*\{([^}]*)\}", m) for item in mo.group(1).split(","))
    wants_value = not has_value and "compiler" not in own and re.search(r"(?<![\w.@])compiler\s*\.", outside) is not None
    if not names and not wants_value:
        return text, []
    items = (["compiler"] if wants_value else []) + ["compiler." + n for n in sorted(names)]
    if wants_value:
        names = ["compiler"] + names
    pat = r"\bimport\s*\{([^}]*)\}\s*;" if in_std else r"\bimport\s*\{([^}]*)\}\s*from\s*\"std\"\s*;"
    std_imports = [mo for mo in re.finditer(pat, text) if m[mo.start()] == "i"]
    if std_imports:
        mo = std_imports[0]
        a, b = mo.start(1), mo.end(1)
        inner = text[a:b]
        if "\n" in inner:
            body = inner.rstrip()
            tail = inner[len(body):]
            ind = re.search(r"\n([ \t]*)\S", inner).group(1)
            sep = "" if body.endswith(",") else ","
            new_inner = body + sep + "".join("\n" + ind + it + "," for it in items) + tail
        else:
            body = inner.rstrip().rstrip(",")
            new_inner = body + ", " + ", ".join(items) + inner[len(inner.rstrip()):]
        return text[:a] + new_inner + text[b:], names
    line = "import {" + ", ".join(items) + "}" + ("" if in_std else ' from "std"') + ";\n"
    imps = list(re.finditer(r"^import\b[^;]*;[ \t]*\n", m, re.M))
    if imps:
        at = imps[-1].end()
        return text[:at] + line + text[at:], names
    # after the leading `////` / `//` comment block
    at = 0
    for mo in re.finditer(r"[^\n]*\n", text):
        if text[mo.start():mo.end()].lstrip().startswith("//") and mo.start() == at:
            at = mo.end()
        else:
            break
    if at:
        return text[:at] + "\n" + line + ("" if text[at:].startswith("\n") else "\n") + text[at:], names
    return line + "\n" + text, names


# ── sites: a rewrite of an original range built from rewritten sub-ranges ───

class Site:
    def __init__(self, start, end, rule, build):
        self.start, self.end, self.rule, self.build = start, end, rule, build


def find_uses(m, name, a, b):
    """Positions of the identifier `name` used as a value in m[a:b]."""
    out = []
    for mo in re.finditer(r"(?<![\w@])" + re.escape(name) + r"(?!\w)", m[a:b]):
        p = a + mo.start()
        if p > 0 and m[p - 1] == "." and not (p > 1 and m[p - 2] == "."):
            continue  # a member `.name`; `..name` / `...name` is a range's operand
        after = skip_ws(m, p + len(name))
        if after < len(m) and m[after] == ":" and not m.startswith("::", after):
            # a label `name: …` — but `cond ? name : x` does not occur in botopink
            continue
        out.append(p)
    return out


def member_after(m, p, name, rend=None):
    """(member, dot, member_end, call_open) for `name.member` at p (the
    receiver ending at `rend`, else after `name`), else None."""
    j = p + len(name) if rend is None else rend
    if j < len(m) and m[j] == "." and not m.startswith("..", j):
        mo = IDENT.match(m, j + 1)
        if mo:
            k = mo.end()
            call = k if k < len(m) and m[k] == "(" else None
            return mo.group(0), j, k, call
    return None


class Run:
    def __init__(self, text, templates=frozenset()):
        self.templates = templates
        self.template_list = []   # (line, shape) of a template call it cannot rewrite
        self.text = text
        self.m = mask(text)
        self.sites = []
        self.counts = collections.Counter()
        self.undecided = []
        self.handle_locals_done = set()

    def add(self, start, end, rule, build):
        self.sites.append(Site(start, end, rule, build))

    def line_of(self, p):
        return self.text.count("\n", 0, p) + 1

    # ── the rules ──

    def plan(self):
        m, t = self.m, self.text
        claimed = set()   # `@Expr` / `@Decl` type positions a rule took
        if self.templates:
            self.plan_template_calls()
        for f in functions(m):
            if f.ret and m.startswith("expr ", f.ret[0]):
                self.plan_interim_template(f)
            if f.ret:
                self.plan_return(f, claimed)
            for (a, b) in f.params:
                self.plan_param(f, a, b, claimed)
        # a record field (or any other `name: @Expr<T>`), 370 (1)'s typed meta
        for mo in re.finditer(r"(?<![\w.])([A-Za-z_]\w*)\s*:\s*(?=@Expr<)", m):
            p = mo.end()
            if p in claimed:
                continue
            ty = type_at(m, p)
            if not ty or ty[0] != "Expr":
                continue
            claimed.add(p)
            _, ia, ib, end = ty
            self.add(p, end, "field @Expr<T> -> T", lambda sub, ia=ia, ib=ib: sub(ia, ib))
        # `@expr(v)` -> v
        for mo in re.finditer(r"@expr\(", m):
            o = mo.end() - 1
            c = match_close(m, o)
            if c < 0:
                continue
            args = split_top(m, o + 1, c)
            if len(args) != 1:
                self.undecided.append((self.line_of(mo.start()), "`@expr` without one argument"))
                continue
            self.add(mo.start(), c + 1, "@expr(v) -> v", lambda sub, a=args[0]: sub(*strip_range(m, *a)))
        # `type T` in a type position -> `type<T>`
        for mo in re.finditer(r"(?<=[<|:,(])(\s*)type\s+([A-Z]\w*)\b(?!\s*[(<{=])", m):
            s = mo.start() + len(mo.group(1))
            self.add(s, mo.end(), "type T -> type<T>", lambda sub, n=mo.group(2): "type<" + n + ">")
        # a bare `type` in a type position -> `anytype` (578 as amended)
        for mo in re.finditer(r"(?:[:<|,]\s*(type)\b(?!\s*[<({:\w]))|(?:->\s*(type)\b(?!\s*[<(:\w]))", m):
            g = 1 if mo.group(1) else 2
            self.add(mo.start(g), mo.end(g), "type -> anytype", lambda sub: "anytype")
        for mo in re.finditer(r"@(Expr|Decl|ExprCustom)\b", m):
            if mo.start() not in claimed:
                self.undecided.append((self.line_of(mo.start()), "a `%s` the codemod has no rule for" % mo.group(0)))

    def plan_template_calls(self):
        # 577 (6): `name "…"` / `name \"\"\"…\"\"\"` / `name("lit")` / `#[name("lit")]` of a
        # template → `name @`…``, the string's escapes resolved to raw bytes.
        m, t = self.m, self.text
        decl_at = set(f.start for f in functions(m))
        for name in sorted(self.templates):
            for mo in re.finditer(r"(?<![\w@])" + re.escape(name) + r"(?!\w)", m):
                p, e = mo.start(), mo.end()
                qualified = p > 0 and m[p - 1] == "."
                if qualified:
                    q = p - 1
                    rm = re.search(r"([a-z_]\w*)$", m[:q])
                    if not rm or (rm.start() > 0 and m[rm.start() - 1] == "."):
                        continue  # a member of a value, not a module's template
                before = m[:p].rstrip()
                if re.search(r"\bfn$", before):
                    continue  # its declaration
                stmt = m[max(m.rfind(";", 0, p), m.rfind("}", 0, p), m.rfind("{", 0, p)) + 1:p]
                if re.match(r"\s*(?:pub\s+)?(?:default\s+)?(?:import|mod)\b", stmt) \
                        or re.search(r"\bimport\s*\{[^}]*$", m[:p]):
                    continue  # an import or a module declaration names the package
                j = skip_ws(m, e)
                after = m[j:j + 2]
                if after == "@`":
                    continue
                if j < len(m) and m[j] == '"' and j > e:
                    lit = string_lit(t, j)
                    if lit:
                        end, raw = lit
                        self.add(j, end, "template \"…\" -> @`…`", lambda sub, raw=raw: template_text(raw))
                        continue
                if j < len(m) and m[j] == ":" and not m.startswith("::", j):
                    continue  # a label
                if j < len(m) and m[j] == "." and not m.startswith("..", j):
                    continue  # `name.member`: the module of that name
                if qualified and not (j < len(m) and m[j] == "("):
                    continue  # a member read of a value of that name
                if j < len(m) and m[j] == "(":
                    c = match_close(m, j)
                    args = split_top(m, j + 1, c) if c > 0 else []
                    if len(args) == 1:
                        aa, ab = strip_range(m, *args[0])
                        lit = string_lit(t, aa) if m[aa] == '"' else None
                        if lit and lit[0] == ab:
                            self.add(e, c + 1, "template(\"lit\") -> template @`…`",
                                     lambda sub, raw=lit[1]: " " + template_text(raw))
                            continue
                        self.template_list.append((self.line_of(p), "`%s(…)` with a non-literal argument" % name))
                    else:
                        self.template_list.append((self.line_of(p), "`%s(…)` with %d arguments" % (name, len(args))))
                    continue
                if j < len(m) and m[j] == "<":
                    self.template_list.append((self.line_of(p), "`%s<…>(…)`, type arguments" % name))
                    continue
                self.template_list.append((self.line_of(p), "`%s` taken as a value" % name))

    def plan_interim_template(self, f):
        """B-136's interim spelling (578 removes it): `-> expr T` → `-> T`; a first
        parameter (after a `self` receiver) `comptime q: string` → `expr q:
        string`, each read of it `compiler.text(q)`."""
        m = self.m
        a = f.ret[0]
        self.add(a, skip_ws(m, a + 4), "-> expr T -> -> T", lambda sub: "")
        firsts = list(f.params)
        if firsts and re.match(r"(?:comptime\s+|expr\s+)?self\s*:", m[firsts[0][0]:]):
            firsts = firsts[1:]
        if not firsts:
            return
        pa, pb = firsts[0]
        mo = re.compile(r"comptime\s+(\w+)\s*:\s*string\s*$").match(m[:pb], pa)
        if not mo:
            return
        name = mo.group(1)
        self.add(pa, pa + len("comptime"), "interim comptime q: string -> expr q: string", lambda sub: "expr")
        for p in find_uses(m, name, *f.body) if f.body else []:
            self.add(p, p + len(name), "interim q -> compiler.text(q)", lambda sub: "compiler.text(" + name + ")")

    def plan_return(self, f, claimed):
        m = self.m
        a, b = f.ret
        ty = type_at(m, a)
        if not ty or ty[0] == "Decl" or ty[3] != b:
            return
        claimed.add(a)
        kind, ia, ib, end = ty
        self.add(a, end, "-> @%s<T> -> -> T" % kind, lambda sub: sub(ia, ib))

    def plan_param(self, f, a, b, claimed):
        m = self.m
        pm = PARAM.match(m, a)
        if not pm or pm.end() > b:
            return
        plain = not pm.group(2)
        ty = type_at(m, pm.end(), bare_decl=plain)
        if not ty or ty[0] == "ExprCustom":
            return
        claimed.add(pm.end())
        kind, ia, ib, tend = ty
        name = pm.group(4)
        if kind == "Decl" and plain:
            # a helper taking a handle: an ordinary parameter (`expr` would make it a decorator)
            self.add(pm.end(), tend, "plain param Decl -> unknown", lambda sub: "unknown")
            uses = find_uses(m, name, *f.body) if f.body else []
            for p in uses:
                self.plan_decl_use(p, name)
            if f.body:
                self.plan_handle_locals(f, name, "Decl")
            return
        mod_start = pm.start(2) if pm.group(2) else (pm.start(3) if pm.group(3) else pm.start(4))
        uses = find_uses(m, name, *f.body) if f.body else []
        dots = "" if not pm.group(3) else ".."
        text_param = kind == "Expr" and self.is_template_text_param(f, a) and self.text[ia:ib].strip() == "string"
        if text_param:
            # 578 (4): a template's text is `expr q: string`; a read of its value
            # is `compiler.text(q)`
            self.add(mod_start, tend, "template text param -> expr q: string",
                     lambda sub: "expr " + dots + name + ": string")
            for p in uses:
                mem = member_after(m, p, name)
                if mem and mem[0] == "value" and mem[3] is None:
                    self.add(p, mem[2], "template q.value -> compiler.text(q)",
                             lambda sub: "compiler.text(" + name + ")")
                else:
                    self.plan_expr_use(p, name, False)
            if f.body:
                self.plan_handle_locals(f, name, "Expr")
            return
        if kind == "Expr":
            others = [p for p in uses if not self.is_value_read(p, name)]
            # a parameter read through `.value` is `comptime`, even when it is also
            # a `fail` / `failAt` location (`at:` names the argument written for it)
            only_value = not others or (len(others) < len(uses)
                                        and all(self.is_fail_use(p, name) for p in others))
            modifier = "comptime" if only_value else "expr"
            self.add(mod_start, tend, "param @Expr<T> -> %s T" % modifier,
                     lambda sub, mo=modifier: mo + " " + dots + name + ": " + sub(ia, ib))
            for p in uses:
                self.plan_expr_use(p, name, only_value)
            if f.body:
                self.plan_handle_locals(f, name, "Expr")
        else:
            self.add(mod_start, tend, "param @Decl -> expr unknown" if ia is None else "param @Decl<T> -> expr T",
                     lambda sub: "expr " + dots + name + ": " + ("unknown" if ia is None else sub(ia, ib)))
            for p in uses:
                self.plan_decl_use(p, name)
            if f.body:
                self.plan_handle_locals(f, name, "Decl")

    def plan_handle_locals(self, f, name, kind):
        """A `val x = <q>.lookup / tagDecl / annotate(…)` of an `@Expr` parameter,
        or `val x = <d>.owner` of an `@Decl` one, holds a handle: its reads and
        outputs take the handle rules for the rest of the body."""
        m = self.m
        a, b = f.body
        if kind == "Expr":
            src = r"%s\s*\.\s*(?:%s)\(" % (re.escape(name), "|".join(HANDLE_SOURCES))
        else:
            src = r"%s\s*\.\s*owner\b" % re.escape(name)
        for mo in re.finditer(r"\bval\s+([A-Za-z_]\w*)(?:\s*:[^=;]*)?\s*=\s*(?:try\s+)?" + src, m[a:b]):
            local = mo.group(1)
            if (a, local) in self.handle_locals_done:
                continue
            start = a + mo.end()
            for p in find_uses(m, local, start, b):
                self.plan_decl_use(p, local, local_rule=True)
            self.handle_locals_done.add((a, local))

    def is_template_text_param(self, f, a):
        """The parameter at `a` is the first (after a `self` receiver) of a
        function declared `-> @Expr<…>` / `-> @ExprCustom<…>`."""
        m = self.m
        if not (f.ret and re.match(r"(@Expr<|@ExprCustom<)", m[f.ret[0]:f.ret[1]])):
            return False
        firsts = [pa for pa, _ in f.params]
        if firsts and re.match(r"(?:comptime\s+|expr\s+)?self\s*:", m[firsts[0]:]):
            firsts = firsts[1:]
        return bool(firsts) and firsts[0] == a

    def is_fail_use(self, p, name):
        mem = member_after(self.m, p, name)
        return bool(mem) and mem[0] in ("fail", "failAt") and mem[3] is not None

    def is_value_read(self, p, name):
        mem = member_after(self.m, p, name)
        if mem:
            return mem[0] == "value"
        # `x is type` tests the value (297)
        return re.compile(r"\s+is\b").match(self.m, p + len(name)) is not None

    def indent_at(self, p):
        ls = self.m.rfind("\n", 0, p) + 1
        return re.match(r"[ \t]*", self.m[ls:]).group(0)

    def call_with_first(self, sub, head, first, call, c):
        """`head(first, <the original arguments>)`, the layout of a multi-line
        argument list kept (`first` on its own line)."""
        m = self.m
        inner = sub(call + 1, c)
        if not m[call + 1:c].strip():
            return head + "(" + first + ")"
        if "\n" in m[call + 1:c] and m[call + 1:skip_ws(m, call + 1)].count("\n"):
            a = skip_ws(m, call + 1)
            return head + "(" + m[call + 1:a] + first + "," + inner + ")"
        return head + "(" + first + ", " + inner.lstrip() + ")"

    def call_with_last(self, sub, head, last, call, c, args):
        """`head(<the original arguments>, last)`, a trailing comma and the
        layout of a multi-line argument list kept."""
        m = self.m
        ab = strip_range(m, *args[-1])[1]
        if "\n" in m[call + 1:c]:
            return head + "(" + sub(call + 1, ab) + ",\n" + self.indent_at(skip_ws(m, args[-1][0])) + last + sub(ab, c) + ")"
        return head + "(" + sub(call + 1, ab) + ", " + last + sub(ab, c) + ")"

    def plan_common(self, p, name, mem):
        """`.text()`, `.fail(m)`, `.failAt(span, m)` on either kind. True when taken."""
        m = self.m
        member, dot, mend, call = mem
        if call is None or member not in ("text", "fail", "failAt"):
            return False
        c = match_close(m, call)
        if c < 0:
            return False
        args = split_top(m, call + 1, c)
        if member == "text" and not args:
            self.add(p, c + 1, "x.text() -> compiler.text(x)", lambda sub: "compiler.text(" + name + ")")
            return True
        if member == "fail" and len(args) == 1:
            self.add(p, c + 1, "x.fail(m) -> compiler.fail(m, at: x)",
                     lambda sub: self.call_with_last(sub, "compiler.fail", "at: " + name, call, c, args))
            return True
        if member == "failAt" and len(args) == 2:
            (sa, sb), (ma, mb) = args
            if "\n" in m[call + 1:c]:
                ind = self.indent_at(skip_ws(m, ma))
                self.add(p, c + 1, "x.failAt(s, m) -> compiler.fail(m, at: x, span: s)",
                         lambda sub: "compiler.fail(\n" + ind + sub(*strip_range(m, ma, mb)) + ",\n" + ind + "at: "
                         + name + ",\n" + ind + "span: " + sub(*strip_range(m, sa, sb)) + ","
                         + m[strip_range(m, ma, mb)[1]:c].lstrip(",") + ")")
            else:
                self.add(p, c + 1, "x.failAt(s, m) -> compiler.fail(m, at: x, span: s)",
                         lambda sub: "compiler.fail(" + sub(*strip_range(m, ma, mb)) + ", at: " + name
                         + ", span: " + sub(*strip_range(m, sa, sb)) + ")")
            return True
        return False

    def plan_expr_use(self, p, name, only_value):
        m = self.m
        mem = member_after(m, p, name)
        if not mem:
            return
        member, dot, mend, call = mem
        if member == "value":
            if only_value:
                self.add(dot, mend, "x.value -> x", lambda sub: "")
            else:
                self.undecided.append((self.line_of(p), "`%s.value` on an `expr` parameter" % name))
            return
        if self.plan_common(p, name, mem):
            return
        if call is not None and member == "parts":
            self.undecided.append((self.line_of(p), "`%s.parts()`: 577 (5): parse the holes from compiler.text(%s)"
                                   % (name, name)))
            return
        if call is not None and member in TEMPLATE_MODEL_NO_EXPR:
            self.add(p, call, "q.<m>(…) -> compiler.<m>(…) (build, note, tagDecl, annotate)",
                     lambda sub: "compiler." + member)
            return
        if call is not None and member in TEMPLATE_MODEL:
            c = match_close(m, call)
            args = split_top(m, call + 1, c)
            self.add(p, c + 1, "q.<m>(…) -> compiler.<m>(q, …)",
                     lambda sub: self.call_with_first(sub, "compiler." + member, name, call, c))
            return
        if call is not None and member == "custom":
            self.plan_custom(p, name, call)
            return
        self.undecided.append((self.line_of(p), "`%s.%s` has no rule" % (name, member)))

    def plan_custom(self, p, name, call):
        m = self.m
        c = match_close(m, call)
        args = split_top(m, call + 1, c)
        # the whole statement `return x.custom(ast, code);`
        line_start = m.rfind("\n", 0, p) + 1
        ret = re.compile(r"[ \t]*return\s+$").match(m, line_start, p)
        semi = skip_ws(m, c + 1)
        if not ret or len(args) != 2 or semi >= len(m) or m[semi] != ";":
            self.undecided.append((self.line_of(p), "`%s.custom(…)` is not a whole `return` statement" % name))
            return
        indent = re.match(r"[ \t]*", m[line_start:]).group(0)
        rs = line_start + len(indent)
        (aa, ab), (ca, cb) = args
        self.add(rs, semi + 1, "return q.custom(ast, code) -> compiler.custom(ast); return code",
                 lambda sub: "compiler.custom(" + sub(*strip_range(m, aa, ab)) + ");\n" + indent
                 + "return " + sub(*strip_range(m, ca, cb)) + ";")

    def plan_decl_use(self, p, name, rend=None, local_rule=False):
        """The handle rules on `name.<member>` at p; `name` is the receiver's text
        (`rend` its end when it is not `name` written at p)."""
        m = self.m
        mem = member_after(m, p, name, rend)
        if not mem:
            return
        member, dot, mend, call = mem
        tag = " (a handle local)" if local_rule else ""
        if rend is None and self.plan_common(p, name, mem):
            return
        if member == "name" and call is None:
            self.add(p, mend, "d.name -> compiler.name(d)!" + tag, lambda sub: "compiler.name(" + name + ")!")
            return
        if member in DECL_READS or member in DECL_RENAMED:
            r = DECL_RENAMED.get(member, member)
            if call is None:
                self.add(p, mend, "d.<r> -> compiler.<r>(d)" + tag, lambda sub: "compiler." + r + "(" + name + ")")
                if member == "owner" and m.startswith("!.", mend):
                    # `d.owner!.<r>`: the owner is a handle too
                    self.plan_decl_use(p, "compiler.owner(" + name + ")!", rend=mend + 1, local_rule=local_rule)
                elif member == "owner" and m.startswith("?.", mend):
                    self.undecided.append((self.line_of(p), "`%s.owner?.…` (a nullable handle's read)" % name))
            else:
                c = match_close(m, call)
                self.add(p, c + 1, "d.<r>(…) -> compiler.<r>(d, …)" + tag,
                         lambda sub: self.call_with_first(sub, "compiler." + r, name, call, c))
            return
        if member in DECL_TYPED_READS and call is not None:
            c = match_close(m, call)
            args = split_top(m, call + 1, c)
            if len(args) == 1:
                (aa, ab), = args
                self.add(p, c + 1, "d.meta(T) -> compiler.meta<T>(d)" + tag,
                         lambda sub: "compiler." + member + "<" + sub(*strip_range(m, aa, ab)) + ">(" + name + ")")
                return
        if member in DECL_OUTPUTS and call is not None:
            c = match_close(m, call)
            args = split_top(m, call + 1, c)
            if member == "setMeta" and args and self.m[skip_ws(m, args[0][0])] == '"':
                self.counts["left: string setMeta(key, value)"] += 1
                return
            self.add(p, call, "d.<output>(…) -> compiler.<output>(…)" + tag, lambda sub: "compiler." + member)
            if member == "addType" and len(args) == 2:
                sa, sb = strip_range(m, *args[1])
                if not m.startswith("compiler.buildType(", sa):
                    # 578 (3): the string source is built (`compiler.buildType`)
                    self.add(sa, sb, "addType(name, src) -> addType(name, compiler.buildType(src))",
                             lambda sub: "compiler.buildType(" + sub(sa, sb) + ")")
            return
        self.undecided.append((self.line_of(p), "`%s.%s` has no rule" % (name, member)))

    # ── applying ──

    def apply(self):
        self.plan()
        sites = sorted(self.sites, key=lambda s: (s.start, -s.end))
        kept = []
        stack = []
        for s in sites:
            while stack and stack[-1].end <= s.start:
                stack.pop()
            if stack and s.end > stack[-1].end:
                self.undecided.append((self.line_of(s.start), "overlapping rewrites (%s)" % s.rule))
                continue
            if any(k.start == s.start and k.end == s.end and k.rule == s.rule for k in kept):
                continue
            kept.append(s)
            stack.append(s)

        def sub(a, b):
            out, i = [], a
            inner = [s for s in kept if s.start >= a and s.end <= b and not (s.start == a and s.end == b and in_build[0] is s)]
            top = []
            limit = a
            for s in inner:
                if s.start >= limit:
                    top.append(s)
                    limit = s.end
            for s in top:
                out.append(self.text[i:s.start])
                prev = in_build[0]
                in_build[0] = s
                out.append(s.build(sub))
                in_build[0] = prev
                self.counts[s.rule] += 1
                i = s.end
            out.append(self.text[i:b])
            return "".join(out)

        in_build = [None]
        return sub(0, len(self.text))


def rewrite(text, templates=frozenset(), in_std=False, template_list=None, imports=False):
    """(new_text, counts, undecided) for one file's text; `templates` the
    template names its scope declares, `template_list` gathers the calls of
    one it cannot rewrite."""
    run = Run(text, templates)
    new = run.apply()
    new, names = add_compiler_imports(new, in_std) if imports else (new, [])
    for n in names:
        run.counts["import {compiler}" if n == "compiler" else "import {compiler.%s}" % n] += 1
    if template_list is not None:
        template_list.extend(run.template_list)
    return new, run.counts, run.undecided


def scope_of(path, roots):
    """The project a file belongs to: the innermost directory holding a
    `botopink.json` that is not a dependency (a cell with its `deps/`, std),
    else the file itself."""
    path = os.path.abspath(path)
    d = os.path.dirname(path)
    while d != os.path.dirname(d):
        if os.path.isfile(os.path.join(d, "botopink.json")) and os.path.basename(os.path.dirname(d)) != "deps":
            return d
        d = os.path.dirname(d)
    return path


def templates_by_scope(paths):
    """{scope: {name}} and [(path, line, name)] of the templates under `paths`."""
    scopes = collections.defaultdict(set)
    decls = []
    for path in files_under(paths):
        with open(path, encoding="utf-8") as fh:
            for name, line in template_decls(fh.read()):
                scopes[scope_of(path, paths)].add(name)
                decls.append((path, line, name))
    return scopes, decls


# ── measurement ──────────────────────────────────────────────────────────────

def measure(text):
    """(counter, setMeta sites, readers) for one file, as the codemod leaves it."""
    new, _, und = rewrite(text)
    m = mask(new)
    c = collections.Counter()
    for _, what in und:
        mo = re.match(r"`(\w+)\.(\w+)` has no rule", what)
        if mo:
            c["%s.%s (left)" % mo.groups()] += 1
        else:
            c[what] += 1
    for mo in re.finditer(r"\bcompiler\.([A-Za-z_]\w*)", m):
        if mo.group(1) not in SPELLED and mo.group(1) not in COMPILER_TYPES:
            c["compiler.%s (no 576 spelling)" % mo.group(1)] += 1
    # reads on a local that holds a declaration handle (a `compiler.lookup` /
    # `annotate` / `tagDecl` answer, a loop over `compiler.methods(d)` …)
    handles = set(mo.group(1) for mo in re.finditer(
        r"\bval\s+(\w+)\s*=\s*compiler\.(?:lookup|annotate|tagDecl|owner)\(", m))
    handles |= set(mo.group(1) for mo in re.finditer(
        r"compiler\.(?:methods|fields|hooks|params|variants|annotations)\([^()]*\)\s*\)?\s*"
        r"(?:\.\s*\w+\(\s*)?\{\s*(\w+)\s*->", m))
    for h in sorted(handles):
        for mo in re.finditer(r"(?<![\w.])" + h + r"\.([A-Za-z_]\w*)", m):
            c["<handle %s>.%s (left)" % (h, mo.group(1))] += 1
    c["addMember(\"name\", …) string form"] += len(re.findall(r"\baddMember\(\s*\"", m))
    c["addType(\"name\", …) string form"] += len(re.findall(r"\baddType\(\s*\"", m))
    c["Declared<"] += len(re.findall(r"\bDeclared<", m))
    c["DeclaredMeta"] += len(re.findall(r"\bDeclaredMeta\b", m))
    c["setMeta(\"key\", value)"] += len(re.findall(r"\bsetMeta\(\s*\"", m))
    c["addMeta("] += len(re.findall(r"\baddMeta\(", m))
    c["wrapWith("] += len(re.findall(r"\bwrapWith\(", m))
    setmeta = []
    fn_starts = [(mo.start(), mo.group(1)) for mo in re.finditer(r"\bfn\s+([A-Za-z_]\w*)", m)]
    for mo in re.finditer(r"\bsetMeta\(\s*\"", m):
        key = re.match(r'"([^"]*)"', new[mo.end() - 1:])
        owner = "?"
        for s0, n in fn_starts:
            if s0 < mo.start():
                owner = n
        setmeta.append((new.count("\n", 0, mo.start()) + 1, owner, key.group(1) if key else "?"))
    readers = []
    for mo in re.finditer(r"\.meta\.([A-Za-z_]\w*)(?:\.([A-Za-z_]\w*))?", m):
        readers.append((new.count("\n", 0, mo.start()) + 1, mo.group(0)))
    for mo in re.finditer(r"\.key\s*==\s*\"", m):
        key = re.match(r'"([^"]*)"', new[mo.end() - 1:])
        readers.append((new.count("\n", 0, mo.start()) + 1, '.key == "%s"' % (key.group(1) if key else "?")))
    return collections.Counter({k: v for k, v in c.items() if v}), setmeta, readers


# ── formatting through today's parser ────────────────────────────────────────
#
# The formatter of a compiler that predates B-136 cannot read `expr x: T` or
# `type<T>`. `to_old` spells them in a form it reads — `x: @Expr<T>` (no
# modifier), `type T` — which nothing else in
# the codemod's output writes (every original `@Expr` and `type T` is
# rewritten), so `to_new` undoes it exactly after the formatter ran.

def _param_type_end(m, a, b):
    """End of a parameter's type in m[a:b] (before a top-level `=` default)."""
    depth, j = 0, a
    while j < b:
        c = m[j]
        if c == "-" and m.startswith("->", j):
            j += 2
            continue
        if c in "([{<":
            depth += 1
        elif c in ")]}>":
            depth -= 1
        elif c == "=" and depth == 0 and not m.startswith("==", j) and not m.startswith("=>", j):
            return strip_range(m, a, j)[1]
        j += 1
    return b


def _edit(text, edits):
    for a, b, r in sorted(edits, reverse=True):
        text = text[:a] + r + text[b:]
    return text


def to_old(text):
    m = mask(text)
    edits = []
    for f in functions(m):
        for a, b in f.params:
            pm = PARAM.match(m, a)
            if not pm or pm.end() > b or pm.group(2) != "expr":
                continue
            te = _param_type_end(m, pm.end(), b)
            edits.append((pm.start(2), pm.end(), text[pm.start(3) if pm.group(3) else pm.start(4):pm.end()]))
            edits.append((pm.end(), te, "@Expr<" + text[pm.end():te] + ">"))
    for mo in re.finditer(r"\btype<([A-Z]\w*)>", m):
        edits.append((mo.start(), mo.end(), "type " + mo.group(1)))
    return _edit(text, edits)


def to_new(text):
    m = mask(text)
    edits = []
    for f in functions(m):
        for a, b in f.params:
            pm = PARAM.match(m, a)
            if not pm or pm.end() > b or pm.group(2):
                continue
            ty = type_at(m, pm.end())
            if ty and ty[0] == "Expr":
                s0 = pm.start(3) if pm.group(3) else pm.start(4)
                edits.append((s0, s0, "expr "))
                edits.append((pm.end(), ty[3], text[ty[1]:ty[2]]))
    for mo in re.finditer(r"(?<=[<|:,(])(\s*)type\s+([A-Z]\w*)\b(?!\s*[(<{=])", m):
        s0 = mo.start() + len(mo.group(1))
        edits.append((s0, mo.end(), "type<" + mo.group(2) + ">"))
    return _edit(text, edits)


def format_through_old(botopink, text, scratch):
    """`text` formatted by `botopink format` through `to_old` / `to_new`, or
    None when the formatter cannot read it."""
    import subprocess
    with open(scratch, "w", encoding="utf-8") as fh:
        fh.write(text)
    if subprocess.run([botopink, "format", scratch], capture_output=True).returncode == 0:
        with open(scratch, encoding="utf-8") as fh:
            return fh.read()  # a formatter that reads the new spellings
    old = to_old(text)
    with open(scratch, "w", encoding="utf-8") as fh:
        fh.write(old)
    r = subprocess.run([botopink, "format", scratch], capture_output=True, text=True)
    if r.returncode != 0:
        return None
    with open(scratch, encoding="utf-8") as fh:
        formatted = fh.read()
    new = to_new(formatted)
    return new if to_old(new) == formatted else None


def format_direct(botopink, text):
    """`text` formatted by `botopink format` as it is, or None when it cannot read it."""
    import subprocess
    import tempfile
    with tempfile.TemporaryDirectory() as tmp:
        f = os.path.join(tmp, "f.bp")
        with open(f, "w", encoding="utf-8") as fh:
            fh.write(text)
        if subprocess.run([botopink, "format", f], capture_output=True).returncode != 0:
            return None
        with open(f, encoding="utf-8") as fh:
            return fh.read()


def is_canonical(botopink, path):
    import subprocess
    return subprocess.run([botopink, "format", "--check", path], capture_output=True).returncode == 0


# ── driver ───────────────────────────────────────────────────────────────────

def files_under(paths):
    for root in paths:
        if os.path.isfile(root):
            yield root
            continue
        for d, dirs, fs in os.walk(root):
            dirs[:] = sorted(x for x in dirs if x not in SKIP_DIRS)
            for f in sorted(fs):
                path = os.path.join(d, f)
                if f.endswith(".bp") and not path.endswith(SKIP_FILES) \
                        and not any(c in path.replace(os.sep, "/") for c in SKIP_CELLS):
                    yield path


def main(argv):
    check = "--check" in argv
    meas = "--measure" in argv
    botopink = None
    if "--format" in argv:
        k = argv.index("--format")
        botopink = argv[k + 1]
        argv = argv[:k] + argv[k + 2:]
    imports = "--imports" in argv
    paths = [a for a in argv if not a.startswith("--")]
    formatted = unformatted = textual = 0
    if not paths:
        print(__doc__)
        return 2
    if meas:
        return run_measure(paths)
    total = collections.Counter()
    changed = 0
    undecided = 0
    template_list, signatures = [], []
    # Phase 1: every rule but the template calls (and the formatter, which reads
    # `name "…"` but not `name @`…``); the templates are then known by 578 (1)'s
    # shape in what phase 1 wrote, project by project.
    staged = []
    scopes = collections.defaultdict(set)
    default_pkgs = collections.defaultdict(set)   # scope -> packages whose default is a template
    for path in files_under(paths):
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        in_std = "/libs/std/" in os.path.abspath(path).replace(os.sep, "/")
        new, counts, und = rewrite(text, frozenset(), in_std, imports=imports)
        canonical = bool(botopink) and not check and new != text and is_canonical(botopink, path)
        if canonical:
            import tempfile
            with tempfile.TemporaryDirectory() as tmp:
                done = format_through_old(botopink, new, os.path.join(tmp, "f.bp"))
            if done is None:
                unformatted += 1
                print("UNFORMATTED %s (the formatter cannot read it through today's parser)" % path)
            else:
                new = done
                formatted += 1
        for name, _ in template_decls(new):
            scopes[scope_of(path, paths)].add(name)
        if package_of_dep(path) and default_template(new):
            default_pkgs[scope_of(path, paths)].add(package_of_dep(path))
        staged.append((path, text, new, counts, und, in_std, canonical))
    # Phase 2: the template calls take the template text (577).
    for path, text, new, counts, und, in_std, canonical in staged:
        tl = []
        sc = scope_of(path, paths)
        templates = frozenset(scopes.get(sc, set()) | default_import_aliases(new, default_pkgs.get(sc, set())))
        if any(c in os.path.abspath(path).replace(os.sep, "/") for c in KEEP_TEMPLATE_CALLS):
            templates = frozenset()
        new2, counts2, und2 = rewrite(new, templates, in_std, tl, imports=imports)
        if botopink and new2 != new and "@`" in new2:
            done = format_direct(botopink, new2) if canonical else None
            if done is not None:
                new2 = done  # a formatter that reads the template text
            else:
                textual += 1
        new = new2
        counts.update(counts2)
        und = und + und2
        template_list += [(path, l, w) for l, w in tl]
        now = set(n for n, _ in template_decls(new))
        signatures += [(path, l, "`%s` was declared `-> @Expr` / `-> @ExprCustom`; its parameters make it no "
                        "template (578 (1))" % n) for n, l in old_template_decls(text) if n not in now]
        for line, what in und:
            print("UNDECIDED %s:%d %s" % (path, line, what))
            undecided += 1
        total.update(counts)
        if new != text:
            changed += 1
            if check:
                print("WOULD CHANGE %s" % path)
            else:
                with open(path, "w", encoding="utf-8") as fh:
                    fh.write(new)
    for path, l, w in template_list:
        print("TEMPLATE-CALL %s:%d %s" % (path, l, w))
    for path, l, w in signatures:
        print("TEMPLATE-SIGNATURE %s:%d %s" % (path, l, w))
    if botopink:
        print("%6d  files formatted, %d left as written; %d with a template text the formatter cannot read"
              % (formatted, unformatted, textual))
    print("%6d  template calls not rewritten, %d `-> @Expr` functions that are no template"
          % (len(template_list), len(signatures)))
    for rule, n in sorted(total.items()):
        print("%6d  %s" % (n, rule))
    print("%6d  files %s" % (changed, "to change" if check else "changed"))
    print("%6d  undecided sites" % undecided)
    return 1 if check and changed else 0


def run_measure(paths):
    per_file = {}
    total = collections.Counter()
    setmeta, readers = [], []
    for path in files_under(paths):
        with open(path, encoding="utf-8") as fh:
            text = fh.read()
        c, sm, rd = measure(text)
        per_file[path] = c
        total.update(c)
        setmeta += [(path, l, d, k) for l, d, k in sm]
        readers += [(path, l, r) for l, r in rd]
    print("# totals")
    for k, v in sorted(total.items(), key=lambda kv: (-kv[1], kv[0])):
        print("%6d  %s" % (v, k))
    print("# per file")
    for path in sorted(per_file):
        if per_file[path]:
            print(path + ": " + ", ".join("%s %d" % (k, v) for k, v in sorted(per_file[path].items())))
    print("# string setMeta sites (file:line decorator key)")
    for path, l, d, k in setmeta:
        print("%s:%d %s %s" % (path, l, d, k))
    print("# string meta readers (file:line read)")
    for path, l, r in readers:
        print("%s:%d %s" % (path, l, r))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
