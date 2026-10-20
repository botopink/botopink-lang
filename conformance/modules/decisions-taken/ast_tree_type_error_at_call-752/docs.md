# Decision 752 — (a): a type error inside a tree `compiler.ast` builds is reported at the `ast` call

The example's build layer (`draft/comptime/build.bp`) declares `labelled`, a function with a `syntax` parameter, expanded at its call. It builds its answer as a typed tree with `compiler.ast`: `Binary("+", Syntax(e), Lit("x"))`, the caller's expression plus a string literal. Written at `labelled(1)`, where `main` expects an `i32`, the tree is ill-typed: an `i32` plus a `string`. The tree carries no location of its own, so the error is reported at the `ast` call, located at the caller's call `labelled(1)` in `main.bp`. The message names `src/comptime/build.bp:<line>:<col>` of the `ast` call and the `Binary` node. A `Syntax(e)` splice keeps the caller's own location, so an error inside the caller's expression would be reported there. The program never builds.

Cells in this repository that bear on it: `modules/decisions-taken/code_never_enters_as_string-625/cells/ast_ill_formed_refused`, `modules/decisions-taken/syntax_node_spliced_as_written-638/cells/ast_syntax_node_typed_at_splice`.

[cells/ast_tree_type_error_at_call/src/main.bp](cells/ast_tree_type_error_at_call/src/main.bp)
