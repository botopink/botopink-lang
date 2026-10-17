# string_code_points_every_width

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> A function of the table is std-wasm's Zig, transpiled into the program, or a hand-written `.wat`
> leaf of `modules/std-wasm/wat/` (front 164 s3), which the compiler reads with its own reader and
> emits into a WasmGC program as one of its functions — `text.length` and `text.charCodeAt` are
> leaves. A leaf names the codegen's GC types (`$str`, `$arr_any`, …) and declares none (decision
> 549); the answer is the same either way:
