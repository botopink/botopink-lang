# Decision 392 — `@Task<T>` behaves as a Promise on every target; on wasm an asynchronous function is a resumable state machine driven by a scheduler.

[cells/generic_thunk_result_binds/src/main.bp](cells/generic_thunk_result_binds/src/main.bp)
[cells/task_await_after_call_refused_on_wasm/src/main.bp](cells/task_await_after_call_refused_on_wasm/src/main.bp)
[cases/task_resumes_in_place/src/main.bp](cases/task_resumes_in_place/src/main.bp)
[cells/task_starts_when_made/src/main.bp](cells/task_starts_when_made/src/main.bp)

Proved also by [wasm_host_async](../one_adapter_list_both_hosts-394/cells/wasm_host_async/src/main.bp)
