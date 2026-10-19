# Decision 336 — `json.parse` and `json.stringify` go; `json.decode` / `json.encode` are the one way, on every target and both wasm hosts

The example reads and writes JSON through the `json` library's two functions, `decode` and `encode`. There is no `parse` or `stringify`, and no host round trip. `decode` is strict. The first document has its members in the order written, and `encode(doc)` writes them back in that order, `{"b":1,"a":[true,null]}`, numbers exact. The second document repeats the member `a`, so `decode` answers an `Error` rather than keeping one of the two, and the program prints `rejected`. An integer past `i64` or an unpaired surrogate is an `Error` the same way. Both functions are botopink bodies, so the library compiles on wasm under `wasi` and `browser` with no host, and the program prints the same two lines on every target.

Cells in this repository that bear on it: `modules/decisions-taken/wasm_attempt_by_exception_handling-518/cases/std_json_on_every_target` (std's `json` until it leaves, 396).

[draft/main.bp](draft/main.bp)
