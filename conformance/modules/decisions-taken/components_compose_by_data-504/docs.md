# Decision 504 — Components compose by data on every target (388 to the end): only a body that awaits is a state machine, the renderer awaits only marked lambdas; `Suspense` and `ErrorBoundary` are tree nodes the renderer resolves while descending. Comptime unchanged.

[cases/component_awaits_host_task/src/main.bp](cases/component_awaits_host_task/src/main.bp)
[cells/component_try_catch_then_awaits_host_task/src/main.bp](cells/component_try_catch_then_awaits_host_task/src/main.bp)
[cells/component_try_then_awaits_host_task/src/main.bp](cells/component_try_then_awaits_host_task/src/main.bp)

Proved also by [context_optional_wide_number_through_scope](../component_is_lambda_over_render_scope-388/cells/context_optional_wide_number_through_scope/src/main.bp)
