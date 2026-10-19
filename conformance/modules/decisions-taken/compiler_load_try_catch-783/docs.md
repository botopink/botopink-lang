# Decision 783 — `compiler.load`'s refusals are handled by a `try … catch` region, as every `Result`; corrects 782 (2), whose `comptime compiler.load(…) catch { ds -> … }` had no `try` — a `catch` with no `try` in its region is `try-region-cannot-fail` (595 (7)).

`try comptime compiler.load(path) catch { ds -> … }` handles a loaded file's refusals in its region: `try` where the
expression begins, its operand the `comptime` read, the handler a block with a binder and at least one statement.
`try comptime compiler.load(path);` with no `catch` propagates the `Error(ds)` to the enclosing function's `Result`.

In the cell `main` handles one load in place; `checked` propagates another to `main`, which handles it; `passes`
loads a file that compiles, so nothing propagates and its body goes on.

[cells/compiler_load_try_catch/src/main.bp](cells/compiler_load_try_catch/src/main.bp)
