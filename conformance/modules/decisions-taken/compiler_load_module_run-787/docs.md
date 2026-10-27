# Decision 787 — A `Module` that compiled can be run: `mod.run()`, called in a `compiler.init` body, runs the loaded package's `main` when the program runs and answers `Result<void, Failure>`; amends 780 (the loaded file is never part of the program) for a module that is run.

`m.run()`, written in a `compiler.init` body, runs the loaded file's `main` when the program runs, at that point
of the init body, and answers `Result<void, Failure>`: `Ok` when `main` returns, `Error(Failure)` when it crashes
— and, by decision 792 (1), when it answers `Error(e)`. The loaded package joins the program for the build's
target, named from its path; a load no `run` reaches stays out of it.

In the cell a top-level `comptime` block calls `runCase`, whose every parameter is `comptime`, once per case
(decision 788): each call loads the package `packages/<case>` and registers an init that prints `== <case>`, runs the
loaded `main` under `try … catch` and prints `end <case>`. `fine`'s `main` returns; `crash`'s panics, answered
`Error` with the panic's message; `err`'s answers `Error("bad answer")`, answered `Error` too, the `Failure`'s
message the error's text. The program's own `main` prints last.

The cell `run_outside_init` calls `run()` in the body that runs at build, outside the init it registers, and is
refused `run-outside-init`; the cell `load_no_main` runs a file that declares no `main`, refused `load-no-main`.

[cases/compiler_load_module_run/src/main.bp](cases/compiler_load_module_run/src/main.bp)
[cases/run_outside_init/src/main.bp](cases/run_outside_init/src/main.bp)
[cases/load_no_main/src/main.bp](cases/load_no_main/src/main.bp)
