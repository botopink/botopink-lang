# abs_aborts_on_i32_overflow

`abs` is declared per width (decision 496): `i32`'s own `abs` holds `i32`'s bound. `(-5).abs()` is `5`, and the lowest
`i32` has no positive counterpart in its type, so `lowest().abs()` aborts with `integer overflow: abs on i32` and the line
after it never runs, on every target alike. The `i64` form is [`abs_aborts_on_overflow`](../abs_aborts_on_overflow/docs.md).
