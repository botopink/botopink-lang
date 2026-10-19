# Decision 502 — A wasm task adapter is the labelled `wasi: .Delay` (481); the prefixed string is refused.

Two host bindings answer a task after a delay, each with one source per target. `pause` names its wasm adapter the way a
`.Wasm` source names everything other than its template, by a label: `wasi: .Delay`, a variant of the enum of adapters
std documents. `later` writes the same adapter as the prefixed string `"wasi:delay"`, the form front 140 first built, and
the program is refused there — at the string, the message naming the labelled form `.Wasm(wasi: .Delay)` to write
instead. The refusal is the checker's on every target, not only under `--target wasm`, so nothing of `run` is printed.

Cells that also bear on it: `modules/external_wasm_prefixed_wasi_refused`, `modules/external_wasm_wasi_cell_not_enum`.

[draft/main.bp](draft/main.bp)
