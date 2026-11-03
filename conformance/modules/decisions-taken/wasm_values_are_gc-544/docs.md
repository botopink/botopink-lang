# Decision 544 — WasmGC for a wasm program's values: what it waits on, and what std-wasm becomes

On wasm every value a program makes is a WasmGC value (the program declares `needs: [.Gc]`), held by the host's
collector: a value is collected once nothing reaches it, so a program whose values die runs in bounded memory however
long it runs. Under the linear-memory model the decision retires, every value stayed in a bump heap that was never
freed, and a long task ended in a trap when the heap was exhausted. Four programs whose values all die young answer
alike on every target: a loop making a string and a record per iteration, ten million short-lived strings, a deep
recursion run many times, and a server's request loop. The bound itself is proven beside the compiler: each program
completes on wasm under a fixed memory cap at ten times the iterations at which the linear-memory model exhausts that
cap (`modules/compiler-core/src/codegen/tests/wat_memory.zig`).

[cases/short_lived_values_loop/src/main.bp](cases/short_lived_values_loop/src/main.bp)
[cases/ten_million_allocations/src/main.bp](cases/ten_million_allocations/src/main.bp)
[cases/deep_recursion_rounds/src/main.bp](cases/deep_recursion_rounds/src/main.bp)
[cases/request_loop/src/main.bp](cases/request_loop/src/main.bp)
