# run_on_module_alias

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> `run-outside-init` names a place, never a receiver (decision 792 (4), (7)): a local alias of the captured
> `Module` (`val m2 = m; m2.run()`) in the init body runs the loaded file's `main` as `m.run()` does.
