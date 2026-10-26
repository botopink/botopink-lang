# val_runs_at_module_load

The reference text this cell shows (from `conformance/docs.md`, § val — immutable binding):

> A `val` at module level is part of the **module body**: it is evaluated **once**,
> in declaration order, when the module loads — before `main` runs and before the
> first `test {}` block. Reading the name afterwards does not evaluate it again,
> and a `_`-named statement, which nothing reads, runs just the same. So a module
> whose initialisers have effects registers itself by being loaded:
