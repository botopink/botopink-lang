# Decision 335 — What a wasm host forbids is a typed error; concurrency fixes results, never interleaving; mocks live in the module's memory.

The program shows the contract the decision fixes for concurrency and for a forbidden request. `async.all` starts three tasks that finish in the order `fast`, `middle`, `slow`, and answers in the order they were given — `slow,fast,middle` — on every target; `async.race` answers the first to complete, `fast`. What the program never depends on is the interleaving of effects between concurrent tasks: that is contract on no target. `explain` is how a program reads a failed `fetch`: every way it fails is an `HttpError`, and on the `browser` wasm host a request the host cannot make — a forbidden header such as `Cookie` or `Host`, or reading `Set-Cookie` — answers `HttpError.NotAllowedOnHost`, never a header dropped in silence; the same request succeeds on wasmtime, node and erlang. The program prints the explanation of that error and of a network failure. std's `testing/mocks` keeps its registry in the wasm module's own memory, the same on both hosts.

Cells in this repository that also bear on it: `modules/std_async_on_every_target`, `modules/http_fetch_request`, `modules/wasm_host_async`.

[draft/main.bp](draft/main.bp)
