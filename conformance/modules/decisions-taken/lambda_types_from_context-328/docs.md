# Decision 328 — A lambda declares no types; its types come from where it is used.

[cases/lambda_arg_generic_param_method/src/main.bp](cases/lambda_arg_generic_param_method/src/main.bp)
[cases/lambda_param_typed_by_later_call/src/main.bp](cases/lambda_param_typed_by_later_call/src/main.bp)
[cases/lambda_param_untyped_method_refused/src/main.bp](cases/lambda_param_untyped_method_refused/src/main.bp)
[cases/generic_result_any_shape/src/main.bp](cases/generic_result_any_shape/src/main.bp) — a generic `apply<T, R>(x: T, f: fn(T) -> R) -> R` answers the type its lambda does, whatever the shape.
