# Decision 792 — `Module.run()`'s open points: `run` answers `Error(Failure)` also when the loaded `main` returns `Error(e)`; the loaded package's body and inits run at `run()`; `Module` is opaque — only `compiler.load` answers one —; three refusals, located at the call; amends 786 (1), 787 (1)–(3).

The loaded package's module body and its `compiler.init`s run at `run()`, just before its `main`, never at program
start: in the cell `module_run_body_at_run` the loaded file's init prints after the caller's init printed
`before run`, then its `main`, then the caller's `after run`, and the program's `main` last. `run()` called twice
on one `Module` runs `main` twice, in one package (`module_run_twice`). A `main` answering `Error(e)` is answered
`Error(Failure)` (decision 787's cell, its `err` case).

`run()` is written directly in the init body: in a function the init body calls it is `run-outside-init`
(`run_in_called_function`). On the `module` of a `Refused` it is `run-module-refused` (`run_module_refused`). A
`Module` is answered by `compiler.load` alone: `Module(…)` written by hand is `module-construction`
(`module_construction`). Each refusal is located at the call.

[cells/module_run_body_at_run/src/main.bp](cells/module_run_body_at_run/src/main.bp)
[cells/module_run_twice/src/main.bp](cells/module_run_twice/src/main.bp)
[cells/run_in_called_function/src/main.bp](cells/run_in_called_function/src/main.bp)
[cells/run_module_refused/src/main.bp](cells/run_module_refused/src/main.bp)
[cells/module_construction/src/main.bp](cells/module_construction/src/main.bp)
