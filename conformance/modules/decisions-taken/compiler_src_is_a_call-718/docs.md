# Decision 718 — `src` is a function of `Compiler`, `fn src(self: Self) -> SourceLocation`, always written with its parentheses; a run-time call may receive its caller's location as an argument the caller writes, `comptime compiler.src()` — an ordinary parameter, (b) — and snap takes 719's form instead, `snap.matches(render(page))`, the location read from the `syntax` argument at the call (amended by 719).

[cells/compiler_at_run_time/src/main.bp](cells/compiler_at_run_time/src/main.bp)
[cells/compiler_src_is_a_call/src/main.bp](cells/compiler_src_is_a_call/src/main.bp)
[cells/src_location/src/main.bp](cells/src_location/src/main.bp)
