# Decision 667 — `v is T` with `T` a type parameter is refused; a type to test against travels as a `comptime t: type<T>` parameter, and `v is t` is the concrete type's test in the function specialised for it.

Cells in this repository that bear on it: `modules/is_type_outside_value_or_type`, `modules/type_param_generic_form`.

[cases/is_type_parameter_refused/src/main.bp](cases/is_type_parameter_refused/src/main.bp)
