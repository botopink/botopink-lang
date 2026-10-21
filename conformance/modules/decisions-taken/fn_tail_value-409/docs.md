# Decision 409 — A function body's last expression written without `;` is its value — in every body: a named `fn`, a method, a `fn` expression and a lambda.

[run/src/cases/decorator_member_fn_tail/mod.bp](run/src/cases/decorator_member_fn_tail/mod.bp)
[refused/src/cases/fn_expr_tail_semicolon/mod.bp](refused/src/cases/fn_expr_tail_semicolon/mod.bp)
[run/src/cases/fn_expr_tail_value/mod.bp](run/src/cases/fn_expr_tail_value/mod.bp)
[run/src/cases/fn_tail_after_loop_return/mod.bp](run/src/cases/fn_tail_after_loop_return/mod.bp)
[run/src/cases/fn_tail_case_arm_block/mod.bp](run/src/cases/fn_tail_case_arm_block/mod.bp)
[run/src/cases/fn_tail_comptime/mod.bp](run/src/cases/fn_tail_comptime/mod.bp)
[run/src/cases/fn_tail_if_else_chain/mod.bp](run/src/cases/fn_tail_if_else_chain/mod.bp)
[run/src/cases/fn_tail_result/mod.bp](run/src/cases/fn_tail_result/mod.bp)
[refused/src/cases/fn_tail_type_mismatch/mod.bp](refused/src/cases/fn_tail_type_mismatch/mod.bp)
[run/src/cases/fn_tail_void_call/mod.bp](run/src/cases/fn_tail_void_call/mod.bp)
[refused/src/cases/init_executor_answers/mod.bp](refused/src/cases/init_executor_answers/mod.bp)
[refused/src/cases/init_executor_named_answers/mod.bp](refused/src/cases/init_executor_named_answers/mod.bp)
[refused/src/cases/method_tail_in_void/mod.bp](refused/src/cases/method_tail_in_void/mod.bp)
[run/src/cases/method_tail_value/mod.bp](run/src/cases/method_tail_value/mod.bp)

Proved also by [block_tail_value](../brace_without_arrow_is_block-525/run/src/cases/block_tail_value/mod.bp)
Proved also by [lambda_last_statement_semicolon](../lambda_answers_last_expression-541/cells/lambda_last_statement_semicolon/src/main.bp)
