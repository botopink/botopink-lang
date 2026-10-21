# external_wasm_op_and_fn

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> | Cell | Binds the declaration to |
> |---|---|
> | `op: "<opcode>"` | one numeric wasm instruction, its text a string (`op: "f64.floor"`, `op: "i32.add"`, `op: "f64.lt"`, `op: "f64.convert_i32_s"`); the declared parameter and return types must be exactly the instruction's — a comparison or `eqz` answers `bool` |
> | `body: <name>` | a botopink identifier, resolved in the module: a private (not `pub`) `fn` of the same module, with a body, taking the same parameter types in the same order and answering the same type — the algorithm stays in the library, in botopink |
> | `wasi: .<Adapter>` | an enum value naming a compiler adapter over the host, one of the list below — each has an implementation per host (WASI preview 2 through the `wasi` component, JavaScript in the `browser` loader), so one list serves both (decision 394) |
> | `std: "<module>.<function>"` | a string naming a function std-wasm implements (checked against std-wasm's exports, never resolved as botopink) — std's host functions written in Zig (`modules/std-wasm`) —, which the compiler transpiles into the program; the declared parameter and return types must be exactly the function's. The same cell is what the comptime answers by, on every target (decision 440). std's alone: a `std:` cell outside `libs/std` is refused (decision 445, below) |
