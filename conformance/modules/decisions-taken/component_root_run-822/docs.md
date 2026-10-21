# Decision 822 — A root runs a component with std's `run`: `pub async fn run<T>(c: Component<T>, scope: Scope) -> Async<T>` — `resolve(c, scope, Place.none())`, awaited only when its answer `is Async<unknown>` —; `resolve` stays the renderer's and `use c`'s.

[cells/component_root_run/src/main.bp](cells/component_root_run/src/main.bp)
