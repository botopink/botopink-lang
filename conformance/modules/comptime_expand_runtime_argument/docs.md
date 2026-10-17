# comptime_expand_runtime_argument

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298), The hooks a function reaches — `decl.hooks`):

> Such a function meets `comptime` values and constants alone: each argument is
> known at build, and a run-time variable passed — a field of one included — is
> `comptime-arg-not-known` at the variable (417).

<!-- example: modules/comptime_expand_runtime_argument -->
