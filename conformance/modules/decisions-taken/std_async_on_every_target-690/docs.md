# Decision 690 — B-25's wasm gate adapters are `.GateNew`, `.GateOpen`, `.GateAwait` (a gate is a pending task no host answers; opening it drops each pending wait's timer); std's test-only cells (`monoMillis`, `hostTarget`, `newCounter`, `countUp`, `countOf`, `panicOf`) stay unbound on wasm until `botopink test` runs wasm (335 (3)).

[cells/std_async_on_every_target/src/main.bp](cells/std_async_on_every_target/src/main.bp)
