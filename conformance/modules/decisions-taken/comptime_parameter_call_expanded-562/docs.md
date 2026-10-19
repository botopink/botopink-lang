# Decision 562 — A function whose body reads a `comptime` parameter's `.value` is expanded at its call site: what depends on build data runs at build, what reaches a run-time value is emitted there as run-time code

[cases/comptime_expand_banner/src/main.bp](cases/comptime_expand_banner/src/main.bp)
[cases/comptime_expand_condition_run_time/src/main.bp](cases/comptime_expand_condition_run_time/src/main.bp)
[cases/comptime_expand_constant_at_build/src/main.bp](cases/comptime_expand_constant_at_build/src/main.bp)
[cases/comptime_expand_library_names/src/main.bp](cases/comptime_expand_library_names/src/main.bp)
[cases/comptime_expand_library_type_error/src/main.bp](cases/comptime_expand_library_type_error/src/main.bp)
[cases/comptime_expand_runtime_argument/src/main.bp](cases/comptime_expand_runtime_argument/src/main.bp)
[cases/typeinfo_all_behavior_call_outside_expansion/src/main.bp](cases/typeinfo_all_behavior_call_outside_expansion/src/main.bp)

Proved also by [stage_build_and_run](../function_stage_propagated-376/cases/stage_build_and_run/src/main.bp)
Proved also by [stage_of_functions](../function_stage_propagated-376/cases/stage_of_functions/src/main.bp)
