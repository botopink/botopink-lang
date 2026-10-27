# Decision 489 — `HostError(message, kind, name, detail)`: `kind` always `"host"`, `name: HostErrorName` the same on every target, `detail` the optional stack; no `target` field. Amends 431.

[cells/external_result_erlang_exit/src/main.bp](cells/external_result_erlang_exit/src/main.bp)

Proved also by [external_result_host_error](../binding_result_true_maps_host_errors-490/cases/external_result_host_error/src/main.bp)
Proved also by [external_result_host_method](../binding_result_true_maps_host_errors-490/cells/external_result_host_method/src/main.bp)
Proved also by [host_node_task_result](../binding_result_true_maps_host_errors-490/cells/host_node_task_result/src/main.bp)
Proved also by [std_failure_attempt_host](../failure_kinds_exact_every_target-527/cells/std_failure_attempt_host/src/main.bp)
Proved also by [std_failure_types](../failure_kinds-492/cases/std_failure_types/src/main.bp)
