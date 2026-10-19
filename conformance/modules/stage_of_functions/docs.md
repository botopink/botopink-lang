# stage_of_functions

The reference text this cell shows (from `conformance/docs.md`, § Typed meta, The hooks a function reaches — `decl.hooks`):

> **Every function's stage** (decision 376). `HookNode.stage` is `Stage.Build`,
> `Stage.Run` or `Stage.Any` — every top-level function has one, whether or not
> it is a component. A function is `Build` when it reads what exists only while
> the program compiles — a `comptime` `@Decl` or `@Expr<T>` parameter
> (`names.value`) of a function that also takes a run-time parameter (one whose
> every parameter is `comptime` is expanded at its call site instead, below) —
> and `Run` when it calls a host function, std's included,
> that is not declared `#[stage(.Any)]` (std's `math` is: a pure primitive);
> anything else — arithmetic, strings, records, arrays, `case`, loops, a method,
> std's `provide` / `context` — is `Any`. A call gives the caller the callee's
> stage (`Any` with `Build` is `Build`, `Any` with `Run` is `Run`), across
> modules as each published its functions; a decorator's or a template's body is
> `Build`.
