# component_return_needs_use

Decisions 791 (1), 809 (4): a body written `-> Component<View>` answers `View`, and a component call only makes the component, a `Component<View>`; a body answering a component resolves it before it returns, so `return mk(1)` answers `mk`'s `View` — `Component<Component<T>>` never arises.
