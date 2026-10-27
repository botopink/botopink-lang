# Decision 518 — `attempt` on wasm by wasm exception handling on every host; a binding declares the host features it needs; STD-001 refuses at the call.

[cases/comptime_attempt_at_build/src/main.bp](cases/comptime_attempt_at_build/src/main.bp)
[cases/external_wasm_needs_unknown/src/main.bp](cases/external_wasm_needs_unknown/src/main.bp)
[cells/std_asserts_host_cell_on_wasm/src/main.bp](cells/std_asserts_host_cell_on_wasm/src/main.bp)
[cells/std_json_on_every_target/src/main.bp](cells/std_json_on_every_target/src/main.bp)
[cells/std_unsupported_refused_at_the_call/src/main.bp](cells/std_unsupported_refused_at_the_call/src/main.bp)

Proved also by [import_std_folder_namespace](../import_alias_on_type_and_folder_namespace-110/cases/import_std_folder_namespace/src/main.bp)
Proved also by [int_division_by_zero_is_panic](../failure_kinds_exact_every_target-527/cases/int_division_by_zero_is_panic/src/main.bp)
Proved also by [std_failure_attempt](../failure_kinds_exact_every_target-527/cases/std_failure_attempt/src/main.bp)
Proved also by [std_failure_attempt_task](../attempt_task_form-494/cases/std_failure_attempt_task/src/main.bp)
