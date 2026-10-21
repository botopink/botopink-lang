# Decision 328 — A lambda declares no types; its types come from where it is used.

[run/src/cases/lambda_arg_generic_param_method/mod.bp](run/src/cases/lambda_arg_generic_param_method/mod.bp)
[cells/lambda_param_typed_by_later_call/src/main.bp](cells/lambda_param_typed_by_later_call/src/main.bp)
[cells/lambda_param_untyped_method_refused/src/main.bp](cells/lambda_param_untyped_method_refused/src/main.bp)
[cells/generic_result_any_shape/src/main.bp](cells/generic_result_any_shape/src/main.bp) — a generic `apply<T, R>(x: T, f: fn(T) -> R) -> R` answers the type its lambda does, whatever the shape.
