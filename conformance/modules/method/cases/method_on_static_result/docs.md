# method_on_static_result

A function-typed record field called like a method answers what its function type returns: `m.make()` with `make: fn() -> Component<View>` is a `Component<View>`, so `run(m.make(), scope)` runs it on every target, as `val c: Component<View> = m.make(); run(c, scope)` does.
