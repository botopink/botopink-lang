# run_in_build_through_value

Decision 720 (a): a call's stage is the called declaration's, and only what is written at the call
counts. `val f = clock.nowMillis; f()` inside a `comptime` passes the checker — it is a call of a
`fn() -> i64` value — and when the build runs the block and reaches `clock.nowMillis`, a function
that runs only when the program runs, the build refuses it: `run-in-build` at the call `f()`,
naming the function reached, with the `comptime` that ran it as the `from` line. The first
`comptime`, which passes `double` along as a value and reaches only `Any` functions, computes `20`.
wasm is left out until std's `io/clock` links there (its host has no wasm cell).
