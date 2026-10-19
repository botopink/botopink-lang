# Decision 560 — The language's wasm runtime is hand-written `.wat`, never Zig building `wat_ast`

The program touches each piece of the language's wasm runtime the decision moves from Zig into hand-written `.wat`: printing (`print` of a string, a number, a `bool`, a tuple and an array — `printing 42 true #(1, 2) [1, 2]`), comparison (structural `==` on records and `>` on strings — `true true`), the `Dict` helpers (`25 2`), the `unknown` helpers behind `is` (`a string a point something else`), the task scheduler (`await later(41)` — `42`), and panic and abort (the program ends in `panic`, `panic: the runtime's abort` on stderr). On every target it answers the same text; on wasm each of those answers now comes from a `.wat` leaf the compiler reads, with Zig keeping only the GC type table and the choice of what the program links. Every cell's answer stayed what it was when the runtime moved — that is the decision's oracle.

Cells in this repository that also bear on it: `modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_panic`.

[draft/main.bp](draft/main.bp)
