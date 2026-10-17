# comptime_expand_boot

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298), The hooks a function reaches — `decl.hooks`):

> **A function expanded at its call site** (decision 562). A function whose
> every parameter is `comptime` and whose body reads one's `.value` has no
> run-time body: each call is replaced by the code its body emits, written where
> the call is — for `boot()` in `main`, in `main`. Its loops over a `comptime`
> value, its conditions, its `val`s and its calls answered from build data alone
> (a `Declared`'s `name`, `module` and `meta`, a literal, another `comptime`
> value, a constant `val` of the module, std's functions over them) run at build,
> and `x.fail(…)` reports there, at the argument. Each statement that reaches a
> run-time value — a `Declared`'s `value`, a host call, a `Stage.Run` function, a
> local the expansion emitted — is emitted, in order, once per iteration of the
> loop that holds it, its build-known parts written into it as constants:
> `say("starting " + d.name); start(d.value);` over three modules emits three
> pairs of calls, in the modules' order. Nothing iterates the catalogue when the
> program runs, and no entry's `value` is called at build.

<!-- example: modules/comptime_expand_boot -->
