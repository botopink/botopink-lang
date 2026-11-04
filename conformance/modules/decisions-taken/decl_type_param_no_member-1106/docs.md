# Decision 1106 — in a decorator tree, a `decl` typed by a type parameter (`<T>(syntax decl: T)`) has no members, as `syntax decl: unknown` has none: `decl.make()` over a bare `T` is the checker's refusal, located at the call, never a fresh result type left unchecked.

`#[service]` declares its handle `syntax decl: T`, `T` a type parameter with no bound, and its executor calls
`decl.make()`. A method on an unbounded type parameter checks nothing, so the error would surface per annotation at
the splice or at run time; the checker refuses the call once, at the decorator, located at `make`, as it refuses
`decl.make()` under `syntax decl: unknown`. The parameter only hands `decl` on to another parameter typed by the same
`T`; a member is read through a declared contract or from the value the decorator built (842 (1)). The program does
not run.

Cells that also bear on it: `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/decl_unknown_no_member`.

[cases/decl_type_param_no_member/src/main.bp](cases/decl_type_param_no_member/src/main.bp)
