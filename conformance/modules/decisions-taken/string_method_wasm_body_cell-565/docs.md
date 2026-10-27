# Decision 565 — A `String` method takes its botopink body on wasm through a `#[@External.Wasm(fn: …)]` cell, wasm alone

The example calls four `string` methods: `padStart`, `repeat`, `replaceAll` and `split`. Each is a `string` method declared in std's `primitives.bp` with an Erlang cell and a JavaScript cell. A method that moved to botopink is bound on wasm by a third cell, `.Wasm(body: <private fn of primitives.bp>)`, whose botopink body is built over the hand-written leaves. Only the wasm target takes that body: commonJS, erlang and beam keep their host cells, so none of their answers moves. To the caller nothing of this shows. The calls are ordinary method calls, and the program prints the same lines on all four targets: `--7`, `ababab`, `a-b-c` and `x|y|z`.

Cells in this repository that bear on it: `modules/decisions-taken/commonjs_text_matches_std_wasm-521/cases/string_lower_final_sigma`.

[draft/main.bp](draft/main.bp)
