# lambda_typed_by_position

Decision 583: every function is typed where it is written. A lambda `{ x -> … }` is legal only where its position fixes
its type — the parameter it is passed to, an annotated `val`, a typed return; elsewhere the typed form
`fn(n: T) -> R { … }` is written. `apply({ n -> n * 2 }, 21)`, `val inc: fn(i32) -> i32 = { n -> n + 1 }` and
`adder`'s returned lambda are typed by their positions, and `half` is written in the typed form. `val later = { n -> n * 3 }`
is typed by nothing — a later call no longer types it (328 amended) — and is refused `lambda-untyped` at the lambda. It
used to build and print `6`.
