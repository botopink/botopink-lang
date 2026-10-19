# Decision 757 — (a): a function with a `comptime t: type<T>` parameter is specialised per type argument — a copy per type, `t` the type inside it — so `v is t` is the concrete type's test and `t` handed on to another call (`self.count(t)`) is a `comptime` argument known at build, as 667 and 417 state.

Cells in this repository that also bear on it: `modules/is_function_type`, `modules/is_enum_variant`.

[cases/comptime_type_token_handed_on/src/main.bp](cases/comptime_type_token_handed_on/src/main.bp)
[cases/is_comptime_type_parameter/src/main.bp](cases/is_comptime_type_parameter/src/main.bp)
[cases/type_parameter_bound_by_token/src/main.bp](cases/type_parameter_bound_by_token/src/main.bp)
