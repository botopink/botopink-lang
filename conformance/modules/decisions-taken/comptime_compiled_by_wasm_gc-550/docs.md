# Decision 550 — Once the Zig term library goes, the comptime is compiled straight by the wasm GC backend; the Erlang layer is deleted

The example computes two values at build: `farthest`, the point of a list furthest from the origin, built from records, a loop and string concatenation, and `firstSquares`, a string of the first five squares. Both `comptime` bodies are ordinary botopink, compiled by the wasm GC backend like any program and run on the comptime runtime, whatever `--target` the build uses. Their answers are spliced in as literals. The program prints `(3, -4)`, `1 4 9 16 25` and `true`, the last because the run-time call of `far` agrees with the value computed at build.

Cells in this repository that also bear on it: `modules/comptime_primitives_at_build`.

[draft/main.bp](draft/main.bp)
