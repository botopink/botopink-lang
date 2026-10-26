# Decision 570 — Without a marker a body returns the whole type: an unmarked `-> Async<T>` / `-> Component<R>` body returning the bare value is a type error; the codemod marks today's such bodies

The `async` marker decides what a body's `return` takes. `marked` carries it, so `return 1` returns the value and the
compiler wraps it into the `Async<i32>` the signature names. `handedOn` carries no marker: it is an ordinary function
whose return type happens to be `Async<i32>`, so it returns a whole `Async<i32>` — `Async.resolve(2)`, std's settled
task. `unmarked` is written like `marked` without the marker, and is refused: `return 3` gives an `i32` where an
`Async<i32>` is expected, a type mismatch whose hint names `async fn` and `Async.resolve`. A caller sees no difference
between the first two — `await` reads both. The same holds for `Component<R>` and the `component` marker.

Cells that also bear on it: `modules/decisions-taken/body_marker_whole_return_type-553/cells/marker_fn_forms`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/marker_type_mismatch`, `modules/decisions-taken/body_marker_whole_return_type-553/cells/marker_lambda_async`.

[cases/async_resolve_unmarked/src/main.bp](cases/async_resolve_unmarked/src/main.bp)
[cells/unmarked_async_bare_value_refused/src/main.bp](cells/unmarked_async_bare_value_refused/src/main.bp)
[cells/unmarked_async_throw_refused/src/main.bp](cells/unmarked_async_throw_refused/src/main.bp)
[cells/unmarked_component_bare_value_refused/src/main.bp](cells/unmarked_component_bare_value_refused/src/main.bp)
