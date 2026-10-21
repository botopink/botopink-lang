# Decision 544 — WasmGC for a wasm program's values: what it waits on, and what std-wasm becomes

The loop makes two million short-lived values — a string and a record per iteration — and keeps only two counters, printing `10888890` and `7999992` on every target. On wasm every value the program makes is a WasmGC value (the program declares `needs: [.Gc]`), held by the host's collector: what an iteration made is collected once nothing reaches it, so the loop runs in bounded memory however long it is. Under the linear-memory model the decision retires, the same loop allocated from a bump heap that was never freed and ended in a trap when the heap was exhausted — the known limit of a long task.

[draft/main.bp](draft/main.bp)
