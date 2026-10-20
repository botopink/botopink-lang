# abs_aborts_on_overflow

`abs` aborts past its integer type, as unary `-` does. `(-5).abs()` is `5` on `i32` and `(-7l).abs()` is `7` on `i64`.
The lowest `i64` has no positive counterpart in its type, so `lowest().abs()` aborts with `integer overflow: abs on i64`
and the line after it never runs, on every target alike.
