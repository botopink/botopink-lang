# Decision 753 — (a): `Node` grows `Fn(params, ret, body)` — a typed parameter list, a return type, a statement body — and the type nodes, one record per kind of the parser's type grammar, measured off 644's mock member and the forms `code` must build.

A typed function is a node of the typed AST: `Fn(params, ret, body)`, a parameter list with its types, a return type
and a statement body, beside the untyped `Lambda` and with one record per kind of the type grammar. So `code` builds a
whole method as a tree. `#[greeter]`, in `draft/comptime/greeter.bp`, hands `addMember` the
code of `fn(self: Self, name: string) -> string { return ${word} + ", " + name; }`, the build value `word` spliced as a
literal — no text is parsed back, and nothing escapes into a raw string. Each annotated type gets its own `greet`, and
the program prints `Hello, Ana` and `Olá, Bia`. `testing/mocks` builds each mock member the same way.

Cells that also bear on it: `modules/decisions-taken/template_marked_by_syntax_text-578/run/src/cases/compiler_template_expr_return`.

[cells/ast_fn_node_builds_mock_member/src/main.bp](cells/ast_fn_node_builds_mock_member/src/main.bp)
[cells/code_template_builds_ast/src/main.bp](cells/code_template_builds_ast/src/main.bp)
