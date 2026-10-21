# syntax_fn_tree_library_type_chain

The code a `syntax` expression function builds is typed where it is spliced (638), and a call chain over the writer's own
generic type is typed link by link though the caller never imports that type (decisions 170, 578, 719, 859): `kit`'s
`evensTimesTen` builds `seqOf(xs).keep(…).pick(…).toArray()` over its private-method type `Seq<T>`, the answer is an
`array<i32>`, and the caller's `join` and `length` run on the array — not on a `Seq` (erlang once ran `join` on the `Seq`
record and crashed with `bp_unsupported_method`).
