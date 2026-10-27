# module_main_async_read_at_build

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> `mainAsync()` is `true` when the loaded package's `main` is `async` (what `run()`'s type follows), read at build
> as `path()` is: `if (comptime loaded.mainAsync())` keeps one branch where the function is expanded.
