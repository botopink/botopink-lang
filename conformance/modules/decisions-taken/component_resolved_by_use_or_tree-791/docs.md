# Decision 791 — A call of a component only makes its lambda, in a component body too; a component is rendered by the tree — a node's child, run from its `render()` — or resolved by `use`, only inside a component body; `await` is for `Async` alone; `Renderable` takes the tree's node, `Renderable<T>`, and rakun-bpp's node child is `NodeChildren = Renderable<Element> | Component<Element>`; amends 388 (4), 416 (1), 553's two cells.

[cases/await_component_at_root/src/main.bp](cases/await_component_at_root/src/main.bp)
[cases/await_component_in_body/src/main.bp](cases/await_component_in_body/src/main.bp)
[cases/behavior_value_unknown_field/src/main.bp](cases/behavior_value_unknown_field/src/main.bp)
[cases/behavior_value_unknown_method/src/main.bp](cases/behavior_value_unknown_method/src/main.bp)
[cases/component_call_lambda_in_body/src/main.bp](cases/component_call_lambda_in_body/src/main.bp)
[cases/component_resolved_by_use_or_tree/src/main.bp](cases/component_resolved_by_use_or_tree/src/main.bp)
[cases/component_return_needs_use/src/main.bp](cases/component_return_needs_use/src/main.bp)
[cells/component_use_in_body/src/main.bp](cells/component_use_in_body/src/main.bp)
