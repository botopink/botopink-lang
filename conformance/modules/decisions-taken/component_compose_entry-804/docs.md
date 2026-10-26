# Decision 804 — `Component<R>` is std's and the language's one concept of a component: the return of a `component` body, or implemented by a type whose `fn compose(self: Self) -> Component<R>` is where it starts; `Renderable` goes from std, the prelude and the compiler; the language does not tell a component from a hook nor knows what a tree's node is — rakun-bpp's `Element` and its children are rakun-bpp's; amends 593 (2), 416 (1), 791 (2), (5).

[cases/component_compose_called/src/main.bp](cases/component_compose_called/src/main.bp)
[cases/component_compose_entry/src/main.bp](cases/component_compose_entry/src/main.bp)
[cells/component_compose_missing/src/main.bp](cells/component_compose_missing/src/main.bp)
[cells/component_compose_signature_differs/src/main.bp](cells/component_compose_signature_differs/src/main.bp)
[cells/component_scope_field/src/main.bp](cells/component_scope_field/src/main.bp)
[cells/component_use_outside_compose/src/main.bp](cells/component_use_outside_compose/src/main.bp)
