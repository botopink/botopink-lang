# Decision 496 — `abs` aborts past its integer type, as unary `-` does, declared per width (`I32`, `I64`).

`abs` is declared on each integer type with that type's bound, and past it aborts as unary `-` does. `(-5).abs()` is
`5` on `i32` and `(-7l).abs()` is `7` on `i64`. The lowest `i64` has no positive counterpart in its type, so
`lowest().abs()` aborts with `integer overflow: abs on i64` — here inside `attempt`, which answers it as a `panic`
`Failure`, the line printing `Error panic: integer overflow: abs on i64 at …`. The last line shows the same bound on
unary `-`: negating the lowest `i32` is not caught, and the program aborts with `panic: integer overflow: - on i32` on
stderr, on every target alike.

Cells that also bear on it: `modules/int_overflow_negate_i32`, `modules/int_overflow_sub_i64_min`,
`modules/abort_text_overflow`.

[draft/main.bp](draft/main.bp)
