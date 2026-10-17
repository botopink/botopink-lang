# hole_known_at_build_raises

The reference text this cell shows (from `conformance/docs.md`, § Template functions):

> A hole
> known at build is evaluated as a `comptime` is, and a value that raises there
> is refused naming the hole, at the call that raised (§ Compile-time
> evaluation), with a `called from` line for each call of the chain down to
> the hole (decision 532).

`${boom}` is known at build and its expansion calls `crash`, which panics: refused at that `@panic`, 8:5.
