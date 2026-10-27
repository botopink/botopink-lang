# Decision 388 — A `@Component<R>` at run time is a lambda over an opaque `RenderScope`; calling a component only makes the lambda, and the render library decides who runs it, when, and with which scope.

[cases/component_is_lambda/src/main.bp](cases/component_is_lambda/src/main.bp)
[cells/component_run_root/src/main.bp](cells/component_run_root/src/main.bp)
[cells/component_try_in_body/src/main.bp](cells/component_try_in_body/src/main.bp)
[cells/context_optional_wide_number_through_scope/src/main.bp](cells/context_optional_wide_number_through_scope/src/main.bp)
[cells/context_wide_number_through_scope/src/main.bp](cells/context_wide_number_through_scope/src/main.bp)
[cells/render_scope_construction/src/main.bp](cells/render_scope_construction/src/main.bp)
[cells/render_scope_library/src/main.bp](cells/render_scope_library/src/main.bp)

Proved also by [component_alias_answers_value](../body_marker_whole_return_type-553/cases/component_alias_answers_value/src/main.bp)
Proved also by [component_hook_and_component](../body_marker_whole_return_type-553/cases/component_hook_and_component/src/main.bp)
