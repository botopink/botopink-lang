# Decision 806 — `run()` answers `Result<void, RunFailure>` — std's `pub type RunFailure(kind: type { Failed, Abort }, message: string)` —, contains everything the loaded package runs, and initialises the package anew at each call; `Failure` is unchanged; amends 787 (1), 792 (1), (2), (6).

`run()` contains everything the loaded package runs: a `panic` in the loaded module body is answered `.Abort` with its
text, a `main` returning `Error(e)` is answered `.Failed` with `e`'s text, and the next `run()` still runs
(`module_run_contains_body_failure`). Each `run()` initialises the package anew: its module body, its `compiler.init`
executors and its `var`s run again before its `main`, so a `var vezes: i32 = 0` incremented by `main` prints 1 on both
runs (`module_run_twice_body`), on commonJS, erlang, beam and wasm. Whatever a `var` is stored in on the BEAM, it starts
at its declaration on each run: an `Ets` var, a keyed `Ets` var and a `PersistentTerm` var, whose initialiser runs at
each run (`module_run_twice_beam_memory`, on erlang and beam).

[cases/module_run_contains_body_failure/src/main.bp](cases/module_run_contains_body_failure/src/main.bp)
[cases/module_run_twice_body/src/main.bp](cases/module_run_twice_body/src/main.bp)
[cases/module_run_twice_beam_memory/src/main.bp](cases/module_run_twice_beam_memory/src/main.bp)
