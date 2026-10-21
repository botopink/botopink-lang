# compiler_load_catch_without_try

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> A `catch` with no `try` in its region is refused `try-region-cannot-fail`, `compiler.load`'s included:
> `comptime compiler.load(path) catch { r -> … }` handles nothing — write `try comptime compiler.load(path) catch { r -> … }`.
