# Decision 888 — An untyped lambda may write fewer parameters than its expected function type has; the omitted ones are trailing, unnamed, and the checker gives the lambda the type's arity; more is still `arity`; the typed form keeps its count; settles 815 (2), 819 (4) against § functions (1).

[cells/lambda_omits_trailing_parameters/src/main.bp](cells/lambda_omits_trailing_parameters/src/main.bp)
[cells/lambda_one_parameter_too_many/src/main.bp](cells/lambda_one_parameter_too_many/src/main.bp)
