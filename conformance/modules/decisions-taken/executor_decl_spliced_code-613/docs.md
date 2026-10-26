# Decision 613 — (d), the rule behind 581 (2): what flows from build into an executor is always admitted — a `comptime` value as a literal, an `syntax` as the code it is, a run-time value as itself — and only the reverse is impossible (611); so `decl` inside an executor is the annotated declaration itself, spliced as code and bound to that declaration, on every kind, and the checker applies its ordinary rules to it, typed by the `syntax decl` parameter's declared type (716).

The three decorators live in the build layer, [draft/comptime/marks.bp](draft/comptime/marks.bp), and each registers
the declaration it annotates through a `compiler.init` executor, writing to the run-time list in
[draft/registry.bp](draft/registry.bp). In every executor `decl` is the annotated declaration itself, spliced as code.
The checker types it by the decorator's `syntax decl` parameter. On the type `Orders`, which `service` takes as a
`Service`, `decl.make()` is `Orders.make()`. On the method `Users.make`, `decl` is that method by its owner's path.
The module's own `fn make` beside it is never what the splice names, so the entry prints `users made`, and the final
`make()` still prints `module make`. On the function `health`, `decl` is the function value. On the `val` `motto`,
it is the value. The names were read at build, before each executor, and enter it as literals. The executors run
before `main` in source order, so the program prints `Orders: orders made`, `make: users made`, `health: healthy`,
`motto: ship it`, then `module make`.

Cells in this repository that also bear on it: `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/run/src/cases/init_executor_handle_on_type`,
`modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/run/src/cases/init_executor_handle_not_module_name`,
`modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cells/init_executor_handle_on_method`,
`modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/init_executor_handle_on_type_as_value`.

[draft/main.bp](draft/main.bp)
