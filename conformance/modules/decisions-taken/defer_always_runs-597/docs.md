# Decision 597 — A `defer` always runs, on every target, whatever goes wrong: a function holding a `defer` adds `.exceptions` to the program's `needs`.

In the example `main` registers `defer print("closed")`, prints `x` and then panics with `y`. The `defer` runs on the way out whatever ends the function, a panic included, so the program prints `x`, then `closed`, then aborts with `panic: y` on stderr. That is one behaviour on commonJS, erlang, beam and wasm. On wasm the `defer` is what makes the program need exception handling: a function holding a `defer` adds `.exceptions` to the program's `needs` with no annotation and no `attempt` anywhere, so the host runs it with the flag that lets the deferred call run before the abort. `defer` is not refused on wasm, and the program's behaviour does not depend on whether an `attempt` stands beside it.

Cells in this repository that bear on it: `modules/defer/cases/defer_panic_attempt_catches`, `modules/decisions-taken/defer_runs_at_block_end-539/cases/defer_inner_panic_runs_once`, `modules/defer/cases/defer_block_end_reverse_order`, `modules/decisions-taken/fs_typed_error_shape-540/cells/fs_file_defer_close`.

[cells/defer_always_runs/src/main.bp](cells/defer_always_runs/src/main.bp)
