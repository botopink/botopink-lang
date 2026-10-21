# Decision 432 — A `@Task<@Result<T, E>>` is the task that fails with `E`: its Promise rejects with `E` and resolves with `T`; a `@Task<T>` does not fail.

[cells/async_retry_policy/src/main.bp](cells/async_retry_policy/src/main.bp)
[cells/task_async_block_in_lambda/src/main.bp](cells/task_async_block_in_lambda/src/main.bp)
[cells/task_lambda_result_unannotated/src/main.bp](cells/task_lambda_result_unannotated/src/main.bp)
[cells/task_result_caught_by_js/src/main.bp](cells/task_result_caught_by_js/src/main.bp)
[cells/task_result_rejects/src/main.bp](cells/task_result_rejects/src/main.bp)

Proved also by [external_result_task_plain_value](../binding_result_true_maps_host_errors-490/refused/src/cases/external_result_task_plain_value/mod.bp)
Proved also by [std_failure_attempt_task](../attempt_task_form-494/cells/std_failure_attempt_task/src/main.bp)
