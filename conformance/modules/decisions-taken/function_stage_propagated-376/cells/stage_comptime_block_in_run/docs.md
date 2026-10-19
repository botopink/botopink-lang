# stage_comptime_block_in_run

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298), The hooks a function reaches — `decl.hooks`):

> **Every function's stage** (decision 376). `HookNode.stage` is `Stage.Build`,
> `Stage.Run` or `Stage.Any` — every top-level function has one, whether or not
> it is a component. A function is `Build` when it reads what exists only while
> the program compiles — a `syntax decl` or a `comptime x: T` parameter
> (`names`) — and `Run` when it calls a host function, std's included,
> that is not declared `#[compiler.stage(.Any)]` (std's `math` is: a pure primitive);
> anything else — arithmetic, strings, records, arrays, `case`, loops, a method,
> std's `provide` / `context` — is `Any`. A call gives the caller the callee's
> stage (`Any` with `Build` is `Build`, `Any` with `Run` is `Run`), across
> modules as each published its functions; a decorator's or a template's body is
> `Build`. A function reaching both is `build-and-run` at the second, naming the
> first. A `comptime` in a body is computed at build into a constant and gives the
> function nothing, so `val names = comptime campos("title,body");` beside a
> clock read is a `Run` function.
