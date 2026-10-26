# Decision 757 — (a): a function with a `comptime t: type<T>` parameter is specialised per type argument — a copy per type, `t` the type inside it — so `v is t` is the concrete type's test and `t` handed on to another call (`self.count(t)`) is a `comptime` argument known at build, as 667 and 417 state.

`count` and `get` each take the type to look for as `comptime t: type<T>`, so each is specialised per type argument: `r.get(Orders)` compiles a copy in which `t` is `Orders`, and inside it `v is t` is the concrete type's test, as `v is Orders` would be. `get` hands `t` on to `self.count(t)`; in the copy, `t` is a type known at build, so it is a valid `comptime` argument — the one place the earlier, run-time reading refused (`expr-value-of-type`). The program prints `2 1`, then `3` — the one `Orders` found and narrowed to its type —, then `true`, because there are two `Users` and `get` answers `null` unless exactly one matches.

Cells in this repository that also bear on it: `modules/is/run/src/cases/is_function_type`, `modules/is/run/src/cases/is_enum_variant`.


[cases/comptime_type_token_handed_on/src/main.bp](cases/comptime_type_token_handed_on/src/main.bp)
[cases/is_comptime_type_parameter/src/main.bp](cases/is_comptime_type_parameter/src/main.bp)
[cases/type_parameter_bound_by_token/src/main.bp](cases/type_parameter_bound_by_token/src/main.bp)
[cases/comptime_type_param_of_method/src/main.bp](cases/comptime_type_param_of_method/src/main.bp)
[cells/comptime_type_token_cross_module/src/main.bp](cells/comptime_type_token_cross_module/src/main.bp)
