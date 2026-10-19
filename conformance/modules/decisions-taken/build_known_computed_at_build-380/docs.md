# Decision 380 — What depends on nothing of the run time is computed at build, wherever it is written — fully, or an error at build.

In the example, `radius` adds 4 to `double(SPACING)`. `SPACING` is a module constant and `double` depends on nothing of the run time, so `r` is the constant `12`, computed at build although no `comptime` is written. `"radius " + radius().toString()` is known at build the same way. `double(n)` with `n` drawn from `io.random` waits for the run, because its input is a run-time value. The dead branch `if (SPACING > 100) panic("never happens")` is a raise written as such, and without `comptime` it is never computed at build: the build succeeds, and the branch stays a run-time raise that is never reached. The program prints `12`, `radius 12`, `6` and `done`; what moved to the build changes no line of the output.

Cells in this repository that also bear on it: `modules/comptime_primitives_at_build`, `modules/template_known_at_build`, `modules/fold_split_join_lambda`.

[draft/main.bp](draft/main.bp)
