# Decision 720 — (a): a call's stage is the called declaration's, and only what is written at the call counts — a call through a function value, a method on a value, a lambda received as a parameter add nothing; the checker checks types, never where a value came from.

A call's stage is the called declaration's, and only what is written at the call counts: the checker checks types,
never where a value came from. The first `comptime` passes a function value along — `val g = double`, handed to
`twice`, called inside it — and every function it reaches is `Any`, so the build computes `20` and the program holds it
as a constant. The second `comptime` writes `val f = clock.nowMillis; f()`. To the checker that is a call of a
`fn() -> i64` value, and it passes; when the build executes the block and reaches `clock.nowMillis`, a `Run` function
that reads the host's clock, the build's runtime raises `run-in-build` at `f()`, located, naming the function reached
and the body being run. The program is refused there and does not run. Written directly, `comptime clock.nowMillis()`
is refused by the checker at the call instead.

Cells that also bear on it: `modules/stage_comptime_block_in_run`, `modules/stage_of_functions`,
`modules/stage_build_and_run`.

[draft/main.bp](draft/main.bp)
