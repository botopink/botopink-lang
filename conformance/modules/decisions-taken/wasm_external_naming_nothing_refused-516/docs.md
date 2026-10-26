# Decision 516 — An `@External.Wasm` cell naming nothing is refused by the checker on every target, not on `--target wasm` alone.

`half` and `double` each carry a JavaScript, an Erlang and a wasm cell. `half`'s wasm cell names `halfBody`, a private
bodied function of the module with the declaration's own types. `double`'s names `doubleBody`, and the module holds
no such function. The checker refuses that annotation, located at the `body:` that resolves to nothing, whichever
target the program is built for. A commonJS, erlang or beam build, which would never run the wasm cell, is refused
the same way as a wasm build. An `op:` absent from the opcode table, an unlisted `wasi:` adapter or a `std:` export
std-wasm does not have would be refused alike. The program does not build on any target, and nothing prints.

Cells in this repository that also bear on it: `modules/decisions-taken/external_wasm_labelled_cells-481/cases/external_wasm_op_unknown`,
`modules/decisions-taken/external_wasm_labelled_cells-481/cases/external_wasm_wasi_unknown`,
`modules/decisions-taken/wasm_attempt_by_exception_handling-518/cases/external_wasm_needs_unknown`.

[draft/main.bp](draft/main.bp)
