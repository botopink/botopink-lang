# component_compose_entry

Decision 804 (1): a type implementing `Component<R>` is a component — its fields are the props, `fn compose(self: Self) -> Component<R>` is its body, and `Card(…)` answers the component, never a record; a call alone only makes the lambda, `use` in a component body runs it under the body's children scope.
