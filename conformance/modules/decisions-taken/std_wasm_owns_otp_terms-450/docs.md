# Decision 450 — The Erlang term library and the OTP functions are std-wasm's; `bp_wat_rt.wasm` goes.

The same function runs twice on the same text: once at build, under `comptime`, on the comptime runtime, and once when the program runs, on the target. Both answers print, then `true`: a function has one face — the text it answers does not depend on whether the comptime runtime or the target computed it, and non-ASCII case mapping (`ß`, `é`) is where two implementations would show. The decision's mechanism — the Erlang term library and the OTP functions living in std-wasm, one wasm runtime instead of two — is itself overtaken by the WasmGC runtime written in botopink and hand-written `.wat` (544, 550, 560); what stands is this answer.

Cells in this repository that also bear on it: `modules/decisions-taken/function_stage_propagated-376/cells/stage_comptime_block_in_run`.

[draft/main.bp](draft/main.bp)
