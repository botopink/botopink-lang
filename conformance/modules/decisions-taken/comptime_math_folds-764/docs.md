# Decision 764 — (a): math's `op:`-only host functions — `sqrt`, `floor`, `abs`, `trunc`, `minF`, `maxF` — gain a `std:` cell each in std-wasm beside their opcode, so the comptime runtime answers them and they fold at build.

The example asks the build for each of math's six opcode functions: `comptime math.sqrt(16.0)`, `math.floor(2.7)`, `math.abs(-3.5)`, `math.trunc(-2.7)`, `math.minF(1.5, 2.5)` and `math.maxF(1.5, 2.5)`. Each has a `std:` cell in std-wasm beside its `op:`, so the comptime runtime can answer it, and the six values are spliced into the program as literals. Without that cell a `comptime` reaching an `op:`-only function is refused. The program prints `4.0 2.0 3.5 -2.0 1.5 2.5`, and then `true`, because `math.sqrt(16.0)` computed at run time, where the program still emits the opcode, gives the same bits as the build did.

Cells in this repository that also bear on it: `modules/comptime_primitives_at_build`.

[draft/main.bp](draft/main.bp)
