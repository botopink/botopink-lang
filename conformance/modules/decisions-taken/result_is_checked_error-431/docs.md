# Decision 431 — `@Result<T, E>` is botopink's checked error — Java's `throws`, Rust's `?` —, and an error that does not arrive as a `@Result` is converted at one boundary: the host binding (`result: true`) or an explicit `attempt`.

[cases/try_catch_host_raise_propagates/src/main.bp](cases/try_catch_host_raise_propagates/src/main.bp)

Proved also by [external_result_erlang_exit](../host_error_fields-489/cells/external_result_erlang_exit/src/main.bp)
Proved also by [external_result_host_error](../binding_result_true_maps_host_errors-490/cases/external_result_host_error/src/main.bp)
Proved also by [external_result_host_method](../binding_result_true_maps_host_errors-490/cells/external_result_host_method/src/main.bp)
Proved also by [external_result_return](../binding_result_true_maps_host_errors-490/cases/external_result_return/src/main.bp)
Proved also by [external_result_return_accepted](../binding_result_true_maps_host_errors-490/cells/external_result_return_accepted/src/main.bp)
Proved also by [external_result_task_plain_value](../binding_result_true_maps_host_errors-490/cases/external_result_task_plain_value/src/main.bp)
Proved also by [host_node_task_result](../binding_result_true_maps_host_errors-490/cells/host_node_task_result/src/main.bp)
Proved also by [std_asserts_throws_over_attempt](../failure_kinds_exact_every_target-527/cases/std_asserts_throws_over_attempt/src/main.bp)
Proved also by [std_failure_attempt](../failure_kinds_exact_every_target-527/cases/std_failure_attempt/src/main.bp)
Proved also by [std_failure_types](../failure_kinds-492/cases/std_failure_types/src/main.bp)
Proved also by [std_host_error_variants](../std_module_error_enum-486/cases/std_host_error_variants/src/main.bp)
