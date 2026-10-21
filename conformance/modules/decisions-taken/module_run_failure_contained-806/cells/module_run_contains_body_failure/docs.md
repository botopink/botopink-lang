# module_run_contains_body_failure

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> `run()` answers `Result<void, RunFailure>`: `.Abort` when the loaded package crashes — in its body, its executors or
> its `main` —, `.Failed` when its `main` returns `Error(e)`; nothing it runs propagates, so the next `run()` runs.
