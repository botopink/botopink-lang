# short_lived_values_loop

A loop makes two million short-lived values — a string and a record per iteration — and keeps only two counters,
printing `10888890` and `7999992` on every target. On wasm every value is a WasmGC value held by the host's collector:
what an iteration made is collected once nothing reaches it, so the loop runs in bounded memory however long it is.
