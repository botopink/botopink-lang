# Decision 364 — Every `comptime` parameter is an expression: `comptime x: @Expr<T>` — a decorator's, a tag annotation's, a template function's, any function's, a builtin's.

[cells/comptime_decorator_section_value/src/main.bp](cells/comptime_decorator_section_value/src/main.bp)
[cells/decorator_arguments_check/src/main.bp](cells/decorator_arguments_check/src/main.bp)
[refused/src/cases/decorator_expr_fail_at_argument/mod.bp](refused/src/cases/decorator_expr_fail_at_argument/mod.bp)
[run/src/cases/decorator_expr_unread_argument/mod.bp](run/src/cases/decorator_expr_unread_argument/mod.bp)
[run/src/cases/decorator_expr_value/mod.bp](run/src/cases/decorator_expr_value/mod.bp)
[refused/src/cases/decorator_inspect_expr_type/mod.bp](refused/src/cases/decorator_inspect_expr_type/mod.bp)
[refused/src/cases/decorator_value_not_comptime/mod.bp](refused/src/cases/decorator_value_not_comptime/mod.bp)
[run/src/cases/expr_param_value_receiver/mod.bp](run/src/cases/expr_param_value_receiver/mod.bp)
