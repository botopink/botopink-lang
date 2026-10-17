#!/usr/bin/env python3
"""Unit tests of compiler_keyword.py (144 B-136's codemod):
`python3 scripts/codemod/test_compiler_keyword.py`."""
import os
import sys
import unittest

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from compiler_keyword import (add_compiler_imports, default_import_aliases, default_template, mask, measure, rewrite,  # noqa: E402
                              template_decls, to_new, to_old)


def rw(src):
    return rewrite(src, imports=True)[0]


class Mask(unittest.TestCase):
    def test_comments_and_strings_blanked_holes_kept(self):
        src = 'val a = "x.value ${q.text()}"; // decl.name\n'
        m = mask(src)
        self.assertEqual(len(m), len(src))
        self.assertNotIn("x.value", m)
        self.assertIn("q.text()", m)
        self.assertNotIn("decl.name", m)


class ExprParam(unittest.TestCase):
    def test_value_only_is_comptime_and_reads_dropped(self):
        self.assertEqual(
            rw("fn f(comptime n: @Expr<i32>) -> i32 {\n    return n.value + n.value;\n}\n"),
            "fn f(comptime n: i32) -> i32 {\n    return n + n;\n}\n")

    def test_value_call_and_is_test_stay_comptime(self):
        self.assertEqual(
            rw("fn f<T>(comptime s: @Expr<Box<T> | type T>) {\n    if (s is type) s.value.value;\n}\n"),
            "fn f<T>(comptime s: Box<T> | type<T>) {\n    if (s is type) s.value;\n}\n")
        self.assertEqual(rw("fn g(comptime r: @Expr<fn() -> bool>) { r.value(); }"),
                         "fn g(comptime r: fn() -> bool) { r(); }")

    def test_unread_or_bodyless_is_comptime(self):
        self.assertEqual(rw("pub declare fn k<T>(comptime source: @Expr<type T>) -> type;"),
                         "pub declare fn k<T>(comptime source: type<T>) -> anytype;")

    def test_rest_parameter(self):
        self.assertEqual(rw("fn f(comptime ..xs: @Expr<Tok[]>) { xs.value; }"),
                         "fn f(comptime ..xs: Tok[]) { xs; }")

    def test_syntax_reads_make_it_expr(self):
        self.assertEqual(
            rw('fn f(comptime x: @Expr<string>) {\n    if (x.text() == "") x.fail("empty");\n}\n'),
            'fn f(expr x: string) {\n    if (compiler.text(x) == "") compiler.fail("empty", at: x);\n}\n')

    def test_handed_on_is_expr(self):
        self.assertEqual(rw("fn f(comptime m: @Expr<string>) { g(message: m); }"),
                         "fn f(expr m: string) { g(message: m); }")

    def test_fail_at(self):
        self.assertEqual(rw('fn f(comptime t: @Expr<string>) { t.failAt(Span(0, 1, 1), "no"); }'),
                         'import {compiler.Span} from "std";\n\n'
                         'fn f(expr t: string) { compiler.fail("no", at: t, span: Span(0, 1, 1)); }')

    def test_value_and_fail_location_is_comptime(self):
        self.assertEqual(rw('fn f(comptime x: @Expr<i32>) { if (x.value > 1) x.fail("big"); }'),
                         'fn f(comptime x: i32) { if (x > 1) compiler.fail("big", at: x); }')

    def test_fail_location_alone_is_expr(self):
        self.assertEqual(rw('fn f(comptime x: @Expr<i32>) { x.fail("no"); }'),
                         'fn f(expr x: i32) { compiler.fail("no", at: x); }')

    def test_value_on_expr_is_left_and_reported(self):
        new, _, und = rewrite('fn f(comptime x: @Expr<i32>) { g(x.value, x); }')
        self.assertEqual(new, 'fn f(expr x: i32) { g(x.value, x); }')
        self.assertEqual(len(und), 1)


class Templates(unittest.TestCase):
    def test_template_model_and_return(self):
        self.assertEqual(
            rw('fn f(comptime q: @Expr<string>) -> @Expr<string> {\n'
               '    for (q.parts()) { p -> p; }\n'
               '    return q.build("\\"\\"");\n}\n'),
            'fn f(expr q: string) -> string {\n'
            '    for (q.parts()) { p -> p; }\n'
            '    return compiler.build("\\"\\"");\n}\n')

    def test_expr_builtin_dropped(self):
        self.assertEqual(rw("fn f(comptime n: @Expr<i32>) -> @Expr<i32> { return @expr(n.value * 2); }"),
                         "fn f(comptime n: i32) -> i32 { return n * 2; }")

    def test_custom(self):
        self.assertEqual(
            rw("fn m(comptime t: @Expr<string>) -> @ExprCustom<i32> {\n"
               "    return t.custom(root, t.build(t.text()));\n}\n"),
            "fn m(expr t: string) -> i32 {\n"
            "    compiler.custom(root);\n"
            "    return compiler.build(compiler.text(t));\n}\n")

    def test_custom_not_a_return_is_reported(self):
        new, _, und = rewrite("fn m(comptime t: @Expr<string>) -> @ExprCustom<i32> { val c = t.custom(r, x); }")
        self.assertIn("t.custom(r, x)", new)
        self.assertEqual(len(und), 1)

    def test_parts_is_undecided(self):
        new, _, und = rewrite("fn f(comptime q: @Expr<string>) -> @Expr<string> {\n    for (q.parts()) { p -> p; }\n}\n")
        self.assertIn("for (q.parts())", new)
        self.assertEqual(len(und), 1)
        self.assertEqual(und[0][0], 2)
        self.assertIn("577 (5)", und[0][1])

    def test_model_members_that_read_no_expr(self):
        self.assertEqual(
            rw('fn f(comptime q: @Expr<string>) -> @Expr<string> {\n'
               '    q.note("n");\n    val t = q.tagDecl(DeclKind.Element, "div", []);\n'
               '    val d = q.annotate(t, Span(start: 0, end: 1, line: 1));\n    return q.build("1");\n}\n'),
            'import {compiler.DeclKind, compiler.Span} from "std";\n\n'
            'fn f(expr q: string) -> string {\n'
            '    compiler.note("n");\n    val t = compiler.tagDecl(DeclKind.Element, "div", []);\n'
            '    val d = compiler.annotate(t, Span(start: 0, end: 1, line: 1));\n    return compiler.build("1");\n}\n')

    def test_handle_locals(self):
        self.assertEqual(
            rw('fn f(comptime q: @Expr<string>) -> @Expr<i32> {\n'
               '    val decl = q.lookup(q.text()) ?? q.fail("none");\n'
               '    val n = decl.name + decl.meta(Check).message;\n'
               '    decl.setMeta(Check(message: n));\n'
               '    return q.build(decl.module);\n}\n'),
            'fn f(expr q: string) -> i32 {\n'
            '    val decl = compiler.lookup(q, compiler.text(q)) ?? compiler.fail("none", at: q);\n'
            '    val n = compiler.name(decl)! + compiler.meta<Check>(decl).message;\n'
            '    compiler.setMeta(Check(message: n));\n'
            '    return compiler.build(compiler.moduleOf(decl));\n}\n')

    def test_handle_locals_per_function(self):
        src = ('fn a(comptime q: @Expr<string>) { val decl = q.lookup("x"); g(decl.name); }\n'
               'fn b(comptime q: @Expr<string>) { val decl = q.lookup("y"); g(decl.name); }\n')
        self.assertEqual(rw(src).count("compiler.name(decl)!"), 2)

    def test_owner_is_a_handle(self):
        self.assertEqual(
            rw('fn r(comptime decl: @Decl) {\n    val owner = decl.owner!;\n'
               '    g(owner.name + owner.module + decl.owner!.name);\n}\n'),
            'fn r(expr decl: unknown) {\n    val owner = compiler.owner(decl)!;\n'
            '    g(compiler.name(owner)! + compiler.moduleOf(owner) + compiler.name(compiler.owner(decl)!)!);\n}\n')

    def test_element_records_left(self):
        src = 'fn r(comptime decl: @Decl) {\n    for (decl.methods) { m -> g(m.name); }\n}\n'
        self.assertEqual(rw(src), 'fn r(expr decl: unknown) {\n    for (compiler.methods(decl)) { m -> g(m.name); }\n}\n')

    def test_multiline_arguments_keep_their_layout(self):
        self.assertEqual(
            rw("fn f(comptime q: @Expr<string>) {\n    q.lookup(\n        a,\n        b,\n    );\n}\n"),
            "fn f(expr q: string) {\n    compiler.lookup(\n        q,\n        a,\n        b,\n    );\n}\n")


class DeclParam(unittest.TestCase):
    def test_reads_and_outputs(self):
        src = ("fn d(comptime decl: @Decl) {\n"
               "    if (decl.kind != DeclKind.Fn)\n"
               "        decl.fail(\n"
               '            "no " + decl.name,\n'
               "        );\n"
               "    decl.setMeta(Mark(n: decl.methods.length));\n"
               "    decl.addMember(\"x\", fn() {});\n"
               "    val m = decl.meta(Mark);\n"
               "    decl.module;\n"
               "}\n")
        self.assertEqual(rw(src),
                         'import {compiler.DeclKind} from "std";\n\n'
                         "fn d(expr decl: unknown) {\n"
                         "    if (compiler.kind(decl) != DeclKind.Fn)\n"
                         "        compiler.fail(\n"
                         '            "no " + compiler.name(decl)!,\n'
                         "            at: decl,\n"
                         "        );\n"
                         "    compiler.setMeta(Mark(n: compiler.methods(decl).length));\n"
                         "    compiler.addMember(\"x\", fn() {});\n"
                         "    val m = compiler.meta<Mark>(decl);\n"
                         "    compiler.moduleOf(decl);\n"
                         "}\n")

    def test_add_type_builds_its_source(self):
        self.assertEqual(rw('fn d(comptime decl: @Decl) { decl.addType("C", "(" + cols + ")"); }'),
                         'fn d(expr decl: unknown) { compiler.addType("C", compiler.buildType("(" + cols + ")")); }')

    def test_imports_off_by_default(self):
        self.assertEqual(rewrite("fn f(s: Span) {}\n")[0], "fn f(s: Span) {}\n")

    def test_generic_decl_keeps_its_type(self):
        self.assertEqual(rw("fn c<T>(comptime decl: @Decl<T>) {}"), "fn c<T>(expr decl: T) {}")

    def test_string_set_meta_left(self):
        new, counts, _ = rewrite('fn d(comptime decl: @Decl) { decl.setMeta("k", "v"); }')
        self.assertEqual(new, 'fn d(expr decl: unknown) { decl.setMeta("k", "v"); }')
        self.assertEqual(counts["left: string setMeta(key, value)"], 1)


class Other(unittest.TestCase):
    def test_record_field(self):
        self.assertEqual(rw("pub type Check<T>(message: @Expr<string>, rule: @Expr<fn(v: T) -> bool>)"),
                         "pub type Check<T>(message: string, rule: fn(v: T) -> bool)")

    def test_bare_type_is_anytype(self):
        self.assertEqual(rw("fn k(comptime t: type, s: Box<type>) -> type { if (t is type) {} }\n"
                            "type F(name: string, type: type)\nval v: type(a: i32) = x;\nfn g(t: type<T>) {}\n"),
                         "fn k(comptime t: anytype, s: Box<anytype>) -> anytype { if (t is type) {} }\n"
                         "type F(name: string, type: anytype)\nval v: type(a: i32) = x;\nfn g(t: type<T>) {}\n")

    def test_type_declarations_untouched(self):
        src = "pub type Box<T>(value: T)\ntype Pair { A, B }\n"
        self.assertEqual(rw(src), src)

    def test_comments_and_strings_untouched(self):
        src = '//// `comptime x: @Expr<T>` reads `x.value`\nval s = "@expr(x)";\n'
        self.assertEqual(rw(src), src)

    def test_idempotent(self):
        src = ("fn f(comptime q: @Expr<string>, comptime decl: @Decl) -> @Expr<string> {\n"
               "    decl.setMeta(Q(s: q.text()));\n    return q.build(\"1\");\n}\n")
        once = rw(src)
        self.assertEqual(rw(once), once)

    def test_measure(self):
        c, setmeta, readers = measure(
            'fn d(comptime decl: @Decl) {\n    decl.setMeta("k", "v");\n    decl.hooks;\n'
            '    val x: Declared<unknown>[] = [];\n}\n'
            'fn r(d: Declared<unknown>) { d.meta.any({ m -> m.key == "k" }); }\n')
        self.assertEqual(c["Declared<"], 2)
        self.assertEqual(c["compiler.hooks (no 576 spelling)"], 0)
        self.assertEqual(setmeta, [(2, "d", "k")])
        self.assertIn((6, '.key == "k"'), readers)


class FormatRoundTrip(unittest.TestCase):
    def test_old_spelling_and_back(self):
        new = ("fn f<T>(expr q: string, comptime n: i32, expr ..xs: T[] , comptime s: Box<T> | type<T>) -> T {\n"
               "    return compiler.build(q, \"1\");\n}\n")
        old = to_old(new)
        self.assertEqual(old, "fn f<T>(q: @Expr<string>, comptime n: i32, ..xs: @Expr<T[]> , "
                              "comptime s: Box<T> | type T) -> T {\n    return compiler.build(q, \"1\");\n}\n")
        self.assertEqual(to_new(old), new)


class Templates577(unittest.TestCase):
    T = frozenset({"sql"})

    def tw(self, src):
        lst = []
        return rewrite(src, templates=self.T, template_list=lst)[0], lst

    def test_call_shapes_rewritten(self):
        new, lst = self.tw('val a = sql "select \\"x\\" `y`";\nval b = sql("a\\nb");\n'
                           '#[sql("q ${id}")]\nfn f() {}\nval c = sql """t""";\n')
        self.assertEqual(new, 'val a = sql @`select "x" \\`y\\``;\nval b = sql @`a\nb`;\n'
                              '#[sql @`q ${id}`]\nfn f() {}\nval c = sql @`t`;\n')
        self.assertEqual(lst, [])
        self.assertEqual(self.tw(new)[0], new)

    def test_other_shapes_listed(self):
        src = 'val a = sql(x);\nval b = sql("a", "b");\nval c = sql<T>("a");\nval d = sql;\nval e = o.sql("a");\n'
        new, lst = self.tw(src)
        self.assertEqual(new, src.replace('o.sql("a")', "o.sql @`a`"))  # a module's template
        self.assertEqual([l for l, _ in lst], [1, 2, 3, 4])

    def test_declaration_not_a_call(self):
        src = 'fn sql(comptime q: @Expr<string>) -> @Expr<string> { return q.build("1"); }\n'
        new, lst = self.tw(src)
        self.assertEqual(lst, [])
        self.assertTrue(new.startswith("fn sql(expr q: string) -> string"))

    def test_template_marked_by_its_text_parameter(self):
        src = ("fn t(expr q: string) -> string { return compiler.build(\"1\"); }\n"
               "fn m(expr self: R, expr q: string) -> i32 {}\n"
               "fn d(expr decl: unknown, expr q: string) {}\n")
        self.assertEqual([n for n, _ in template_decls(src)], ["t", "m"])


class Templates578(unittest.TestCase):
    def test_value_only_text_is_expr_and_read_through_text(self):
        self.assertEqual(rw('fn shout(comptime q: @Expr<string>) -> @Expr<string> { return @expr(q.value + "!"); }'),
                         'fn shout(expr q: string) -> string { return compiler.text(q) + "!"; }')

    def test_template_method_keeps_its_receiver(self):
        self.assertEqual(rw("fn t(comptime self: @Expr<G>, comptime q: @Expr<string>) -> @Expr<string> "
                            "{ return q.build(self.text()); }"),
                         "fn t(expr self: G, expr q: string) -> string "
                         "{ return compiler.build(compiler.text(self)); }")

    def test_non_template_expr_return(self):
        self.assertEqual(rw("fn d(comptime n: @Expr<i32>) -> @Expr<i32> { return @expr(n.value * 2); }"),
                         "fn d(comptime n: i32) -> i32 { return n * 2; }")

    def test_interim_spelling(self):
        self.assertEqual(rw("fn shout(comptime q: string) -> expr string {\n    return q.toUpper();\n}\n"
                            "fn same(expr q: string) -> expr string { return q; }\n"),
                         "fn shout(expr q: string) -> string {\n    return compiler.text(q).toUpper();\n}\n"
                         "fn same(expr q: string) -> string { return q; }\n")

    def test_method_call_rewritten(self):
        lst = []
        self.assertEqual(rewrite('g.shout("hi");\n', frozenset({"shout"}), False, lst)[0], "g.shout @`hi`;\n")


class DefaultTemplate(unittest.TestCase):
    def test_a_package_default_template_is_called_by_its_import_name(self):
        self.assertTrue(default_template("pub default fn badge(expr t: string) -> Badge { return x; }\n"))
        self.assertFalse(default_template("pub fn badge(expr t: string) -> Badge { return x; }\n"))
        self.assertEqual(default_import_aliases('import badges from "badges";\nimport s, {a} from "shapes";\n',
                                                {"badges", "shapes"}), {"badges", "s"})


class Imports(unittest.TestCase):
    def test_merged_into_the_std_import(self):
        self.assertEqual(add_compiler_imports('import {bpp} from "std";\nval k = DeclKind.Fn;\n', False)[0],
                         'import {bpp, compiler.DeclKind} from "std";\nval k = DeclKind.Fn;\n')

    def test_new_import_after_the_header(self):
        self.assertEqual(add_compiler_imports('//// doc\n\nfn f(s: Span) {}\n', False)[0],
                         '//// doc\n\nimport {compiler.Span} from "std";\n\nfn f(s: Span) {}\n')

    def test_std_form_and_own_declarations(self):
        self.assertEqual(add_compiler_imports('fn f(s: Span) {}\n', True)[0],
                         'import {compiler.Span};\n\nfn f(s: Span) {}\n')
        src = 'type Field(name: string)\nval f = Type.Field;\nfn g(Span: i32) {}\n'
        self.assertEqual(add_compiler_imports(src, False)[0], src)

    def test_idempotent(self):
        once = add_compiler_imports('import {io} from "std";\nfn f(s: Span) {}\n', False)[0]
        self.assertEqual(add_compiler_imports(once, False)[0], once)


if __name__ == "__main__":
    unittest.main()
