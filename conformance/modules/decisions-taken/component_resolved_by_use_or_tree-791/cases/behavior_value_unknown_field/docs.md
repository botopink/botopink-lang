# behavior_value_unknown_field

B-162 (decisions 791, 809 (1)): a `Component<View>` — the component a call makes — is a `Composition` or a `Composable` and has no member of its own; `c.zzz` is an unknown field, refused at the name. It is resolved by `use c` in a component body or run from a root with `await run(c)`.
