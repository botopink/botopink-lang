# hole_any_call_raises

The reference text this cell shows (from `conformance/docs.md`, § Template functions):

> **A hole known at build** (decision 355). Each `Interp` part of `q.parts()`
> carries `known` and `value`: `known` is true when the hole's value is known
> while the program compiles — a literal, a `comptime` value, a `val` of the
> module — or one another module exports — whose initializer is known at build, a template call (another
> expansion) whose every argument is, an operator over such values, or a call of an `Any` function
> (decision 376) that writes no raise, no output and no module `var` and calls only such functions,
> its every argument known at build (decision 380: `${padAll(2)}`, `${padAll(ESPACO)}`) — and `value`
> is that value, read as data (a record is its fields); for any other hole (a parameter, a local, a
> call of a `Run` function or of one that prints) `known` is false and `value` is `null`, and the hole is the program's to
> compute. The rule reads the hole's value, never the literal's text. A hole
> known at build is evaluated as a `comptime` is, and a value that raises there
> is refused naming the hole, at the call that raised (§ Compile-time
> evaluation), with a `called from` line for each call of the chain down to
> the hole (decision 532). So a template can write its answer as a constant when
> every hole is known — `styled "${tab4} color: red;"` with `tab4 =
> styledProperty "tab-size: 4;"` is emitted as `styledConstant("s_…",
> ".s_…{tab-size:4;color:red}")` — and leave the holes to the program otherwise:
