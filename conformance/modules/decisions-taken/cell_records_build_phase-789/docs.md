# Decision 789 — `cell check` records the build phase before the run: one `build <text>` record per line a build body prints; a conformance module is one package whose `src/main.bp` loads each case and prints its answer, recorded by `cell check` with no `snap` dependency; amends 475 (2) (a new record), 781 (`run/` / `refused/` fold into one package), 784 (2)–(4).

A conformance module's `src/main.bp` holds `runCase(comptime name)`, called by a top-level `comptime { … }` for each
case and expanded there (decision 788). Its load is handled and left on — `val loaded = try comptime
compiler.load(…) catch { r -> compiler.init({ … }); return; };` —, and since the block answers the load at build, the
branch is taken at build: in the cell `comptime_load_try_catch_return_in_expansion` the `broken` case registers the
init that prints its refusals and stops there, the `fine` case binds its `Module` and registers the init that runs it.

[cells/comptime_load_try_catch_return_in_expansion/src/main.bp](cells/comptime_load_try_catch_return_in_expansion/src/main.bp)
