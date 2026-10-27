# gc_behavior_values

A value typed by a behavior — the module's own, an ambient one (`Closeable`, `Index<K, V>`), an array of them — is any implementer's, a record or a variant, and a method call on it answers the implementer's method; on wasm the GC lowering holds it as the implementer's reference and dispatches by `ref.test` (decision 1021 (10)).
