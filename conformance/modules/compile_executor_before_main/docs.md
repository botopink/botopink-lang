# compile_executor_before_main

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A decorator compiles run-time code beside the annotated declaration with
> `compiler.compile(executor)` (decision 575 (3)): the executor, a function of
> no parameter written at the call (`compiler.compile({ -> register(name) })`)
> or named there, runs once before `main`, in the program's init list —
> modules in dependency order, declarations in source order, the calls in the
> order the bodies make them; a declaration takes any number. The executor is
> checked against `fn()` (decision 409): a tail that answers a value is refused
> at it, a named executor that answers one at its name. The executor is a tree (575 (4)): run-time code whose names
> resolve where the decorator wrote it — a private helper of the decorator's
> module included, a library's too —, each `expr` parameter spliced as the
> expression written, each `comptime` parameter and each `val` of the body
> spliced as the literal of its value. A library module's executors run in the
> program that imports it, before the program's own.
