# comptime_load_try_catch_return_in_expansion

The reference text this cell shows (from `conformance/docs.md`, § A top-level `comptime { … }`):

> A load the function handles and leaves on (decision 789 (4)) — `val loaded = try comptime
> compiler.load(…) catch { r -> …; return; };` — takes its branch at build when the block expands the
> function: on `Error` the handler's statements are the block's and the `return` ends the expansion; on
> `Ok` the `Module` is bound and the statements after it are the block's.
