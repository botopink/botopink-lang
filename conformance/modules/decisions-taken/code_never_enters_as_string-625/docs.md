# Decision 625 — (b) for the computed member, and the rule behind it: code never enters the compiler as a string — it is written (a `syntax` parameter, a template text) or built as the typed AST; `compiler.build(text)` is removed and `compiler.ast(node) -> anyvalue` takes its place.

[cells/ast_ill_formed_refused/src/main.bp](cells/ast_ill_formed_refused/src/main.bp)
[cells/template_answers_ast/src/main.bp](cells/template_answers_ast/src/main.bp)
