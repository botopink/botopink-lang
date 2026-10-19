# Decision 751 — (a), as built: `Call(callee: …, args: …)`, `Node` a closed union alias, the vocabulary the parser has, `compiler.ast`'s argument checked in the reply.

`doubledInRange` takes the caller's expression as `syntax value` and returns code built from `compiler.bp`'s `Node` records, never from text: a `Binary` multiplying a `Syntax(e: value)` — the caller's expression, spliced as written and typed where it stands — by a `Lit`, passed as the first argument of a `Call` whose callee is the `Name` `clamp`. The call is `Call(callee: …, args: …)`, `callee` because `fn` is reserved; a construction is a `Call` too, there being no `Record` or `Field` node. `Node` is a closed union of exactly the parser's kinds, and `compiler.ast` checks its argument in the reply. The names the built code holds resolve in the builder's module, so `clamp` is found there and the caller imports nothing beyond `doubledInRange`. The program prints `6`, `10` (`14` clamped) and `0` (`-2` clamped).

Cells in this repository that also bear on it: `modules/decisions-taken/syntax_node_spliced_as_written-638/cells/ast_syntax_node_typed_at_splice`, `modules/decisions-taken/code_never_enters_as_string-625/cells/ast_ill_formed_refused`.

[draft/main.bp](draft/main.bp) · [draft/comptime/build.bp](draft/comptime/build.bp)
