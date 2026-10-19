# Decision 555 — wasmtime does not collect cycles yet: the codegen breaks its own

`main` makes and awaits a hundred thousand tasks, one after another, and prints `99999`. Each task, once settled, would point back at the frame and the waiters that point at it — a cycle the wasm codegen itself would create. wasmtime's collector does not follow cycles yet, so the codegen leaves none of its own making: a settled task drops its waiters and its frame, and every task here is freed as soon as it is awaited, so the loop's memory stays bounded on wasm as on the other targets. A cycle the program itself builds may live until the program exits.

[draft/main.bp](draft/main.bp)
