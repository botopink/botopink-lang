# Decision 496 — `abs` aborts past its integer type, as unary `-` does, declared per width (`I32`, `I64`).

`abs` is declared on each integer type with that type's bound, and past it aborts as unary `-` does. `(-5).abs()` is
`5` on `i32` and `(-7l).abs()` is `7` on `i64`. The lowest `i64` has no positive counterpart in its type, so
`lowest().abs()` aborts with `integer overflow: abs on i64` — here inside `attempt`, which answers it as a `panic`
`Failure`, the line printing `Error panic: integer overflow: abs on i64 at …`. The last line shows the same bound on
unary `-`: negating the lowest `i32` is not caught, and the program aborts with `panic: integer overflow: - on i32` on
stderr, on every target alike.

Cells that also bear on it: `modules/decisions-taken/integer_overflow_aborts-264/cases/int_overflow_negate_i32`, `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/int_overflow_sub_i64_min`,
`modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_overflow`.

[cases/abs_aborts_on_i32_overflow/src/main.bp](cases/abs_aborts_on_i32_overflow/src/main.bp)
[cases/abs_aborts_on_overflow/src/main.bp](cases/abs_aborts_on_overflow/src/main.bp)
