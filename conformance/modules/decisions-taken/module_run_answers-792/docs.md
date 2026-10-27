# Decision 792 — `Module.run()`'s open points: `run` answers `Error(Failure)` also when the loaded `main` returns `Error(e)`; the loaded package's body and inits run at `run()`; `Module` is opaque — only `compiler.load` answers one —; three refusals, located at the call; amends 786 (1), 787 (1)–(3).

The loaded package's module body and its `compiler.init`s run at `run()`, just before its `main`, never at program
start: in the cell `module_run_body_at_run` the loaded file's init prints after the caller's init printed
`before run`, then its `main`, then the caller's `after run`, and the program's `main` last. `run()` called twice
on one `Module` runs `main` twice, in one package (`module_run_twice`). A `main` answering `Error(e)` is answered
`Error(Failure)` (decision 787's cell, its `err` case).

`run()` is written directly in the init body: in a function the init body calls it is `run-outside-init`
(`run_in_called_function`). On the `module` of a `Refused` it is `run-module-refused` (`run_module_refused`). A
`Module` is answered by `compiler.load` alone: `Module(…)` written by hand is `opaque-construction`
(`module_construction`; decision 811 (4) made std's `Module` an opaque type). Each refusal is located at the call. `run-outside-init` names a place: a local alias of
the captured `Module` in the init body runs `main` (`run_on_module_alias`); a receiver traced to no load of the body
is `run-module-untraced`.

[cells/module_run_body_at_run/src/main.bp](cells/module_run_body_at_run/src/main.bp)
[cells/module_run_twice/src/main.bp](cells/module_run_twice/src/main.bp)
[cases/run_in_called_function/src/main.bp](cases/run_in_called_function/src/main.bp)
[cases/run_module_refused/src/main.bp](cases/run_module_refused/src/main.bp)
[cases/module_construction/src/main.bp](cases/module_construction/src/main.bp)
[cells/run_on_module_alias/src/main.bp](cells/run_on_module_alias/src/main.bp)
[cases/sibling_declares_tok/src/main.bp](cases/sibling_declares_tok/src/main.bp)
[cases/sibling_decorator_named_all/src/main.bp](cases/sibling_decorator_named_all/src/main.bp)
[cases/sibling_exports_all/src/main.bp](cases/sibling_exports_all/src/main.bp)
[cases/sibling_exports_all_again/src/main.bp](cases/sibling_exports_all_again/src/main.bp)
[cases/sibling_std_code_template/src/main.bp](cases/sibling_std_code_template/src/main.bp)
