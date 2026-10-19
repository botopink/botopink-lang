# Decision 531 — A dependency function wasm cannot lower, which the program never calls: does it stop the build?

The example imports std's `io.process` and never calls it. On wasm none of `io.process`'s functions can be lowered, because their host cells have no wasm form. That stops nothing here: a dependency's function the program never reaches is not lowered and is not refused, and the import only brings names into scope. `main` reaches `path.join`, which has a wasm form, so the program builds and runs on every target, wasm included, and prints `a/b.txt`. Had `main` called `process.run(…)`, the wasm build would be refused at that call, located, naming the function and what it lacks, never at the import. Code that runs at build follows the same rule: such a function is an error only where a decorator, a template or a `comptime` reaches it.

Cells in this repository that bear on it: `modules/decisions-taken/wasm_attempt_by_exception_handling-518/cells/std_unsupported_refused_at_the_call`, `modules/std/cells/std_unsupported_names_the_call`.

[draft/main.bp](draft/main.bp)
