# component_return_needs_use

Decision 791 (1), (3): a body written `-> Component<View>` answers `View`, and a component call only makes its lambda, a `Component<View>`; `return mk(1)` is a type mismatch, the hint naming `use` — `val v = use mk(1); return v;` resolves it.
