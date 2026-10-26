# Decision 490 — A binding answers a `@Result` from its host only under `result: true` (431's `throws: true` renamed), and every way the host fails becomes `Error(HostError(…))`; 126's implicit Promise conversion is retired. Amends 431, 126.

[cases/external_result_host_error/src/main.bp](cases/external_result_host_error/src/main.bp)
[cells/external_result_host_method/src/main.bp](cells/external_result_host_method/src/main.bp)
[cases/external_result_not_bool/src/main.bp](cases/external_result_not_bool/src/main.bp)
[cases/external_result_return/src/main.bp](cases/external_result_return/src/main.bp)
[cells/external_result_return_accepted/src/main.bp](cells/external_result_return_accepted/src/main.bp)
[cases/external_result_task_plain_value/src/main.bp](cases/external_result_task_plain_value/src/main.bp)
[cells/host_node_task_result/src/main.bp](cells/host_node_task_result/src/main.bp)
