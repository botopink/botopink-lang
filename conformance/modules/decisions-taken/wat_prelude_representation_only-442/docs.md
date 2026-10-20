# Decision 442 — `wat_prelude` keeps only what defines a value's representation or talks to the host; everything that only computes over values is Zig, transpiled as std-wasm is (440).

The decision is about where the wasm runtime keeps its helpers, and its rule (3) is what survives the move to WasmGC
(544, 560): a helper stays in the codegen when it reads or writes the layout the codegen decides or talks to the host,
and is written elsewhere — in botopink or a `.wat` leaf — when it only takes values and answers values. What a program
sees is that no answer moves: the example exercises one helper of each family the rule sorts — text (`trim`,
`toUpper`, `split`, `replace`, `padStart`, `lastIndexOf`), number to text (`1.5`, an `i64`, `1.0e21`), arrays
(`reverse`, `unique`, `slice`, `join`), and the seeded random stream — and prints on wasm exactly what it prints on the
other targets: `MIXED CASE, WORDS`, `["Mixed Case", "words"]`, `a+b-c`, `007`, `4`, `1.5`, `2147483648`, `1.0e21`,
`[2, 3, 1, 3]`, `[3, 1, 2]`, `[1, 3]`, `3|1|3|2`, `true`.

[cells/wat_prelude_representation_only/src/main.bp](cells/wat_prelude_representation_only/src/main.bp)
