# Decision 503 — `testing.asserts` imports on wasm, its API unchanged; `matches` waits on std's regex there, a located refusal until then. Amends 146.

`testing.asserts` imports on wasm and its API is the same as on the other targets. `throws` and `throwsWith` run over
`failure.attempt`, which uses exception handling on wasm (518). `deepEquals` compares through a botopink body and
needs no host cell. `matches` waits on std's regex on wasm. Until that lands, a call that reaches `regexMatches` on
wasm is refused at the call, located, and the import itself is not refused.

The example imports `testing.asserts` and never calls `matches`, so it builds on every target, wasm included. It
prints `ok` for an `equals` that holds and for a `deepEquals` of two equal records, and `failed: …` with the helper's
message for two arrays that differ. `throws` prints `ok` for a body that panics and `failed: …` for one that returns.

Cells that also bear on it:
`modules/decisions-taken/wasm_attempt_by_exception_handling-518/cells/std_asserts_host_cell_on_wasm`
(the `deepEquals` path on wasm while `canonical` has no botopink body).

[draft/main.bp](draft/main.bp)
