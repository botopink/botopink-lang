# comptime_expand_banner

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298), The hooks a function reaches — `decl.hooks`):

> Each statement that reaches a run-time value — a `Declared`'s `value`, a host
> call, a `Stage.Run` function, a local the expansion emitted — is emitted, in
> order, once per iteration of the loop that holds it, its build-known parts
> written into it as constants.

<!-- example: modules/comptime_expand_banner -->
