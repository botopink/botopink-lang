# comptime_expand_condition_run_time

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298), The hooks a function reaches — `decl.hooks`):

> A loop's bound or a condition that needs a run-time value is refused at it,
> `run-in-build`, naming the value: `if (d.value is fn() -> string)` is decided
> at build, where `d.value` is not.

<!-- example: modules/decisions-taken/comptime_parameter_call_expanded-562/refused/src/cases/comptime_expand_condition_run_time -->
