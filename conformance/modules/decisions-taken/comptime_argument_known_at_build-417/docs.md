# Decision 417 — A `comptime` argument of an ordinary function is known at build.

`tag` takes `n` as a `comptime` parameter and never reads it. `tag(2, 1)` passes a literal, known at build, and is fine. `tag(k, 1)` passes a local `var`, a run-time value, and the program is refused at `k` with `comptime-arg-not-known` — read or not, an ordinary function's `comptime` parameter is its specialisation, so its argument must be known while the program compiles. Only a decorator accepts an argument it does not read that is not known at build.

Cells in this repository that also bear on it: `modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/comptime_arg_not_known`, `modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_runtime_argument`.

[draft/main.bp](draft/main.bp)
