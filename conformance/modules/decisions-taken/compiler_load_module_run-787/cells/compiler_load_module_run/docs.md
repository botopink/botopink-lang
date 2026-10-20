# compiler_load_module_run

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> `m.run()`, written in a `compiler.init` body, runs the loaded file's `main` when the program runs, at
> that point of the init body: `Ok` when `main` returns, `Error(Failure)` when it crashes or answers
> `Error(e)`.
