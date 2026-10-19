# Decision 573 — The keyword without its marker is refused under the marker's name, renamed now

The example writes `await` in `total`, a function with no `async` marker. The keyword is refused under the marker's name, `await-without-async`, at the `await`, and the hint names what to write: `async fn`. The other two keywords follow the same rule: `yield` in a body with no `iter` marker is `yield-without-iter`, and `use` in a body with no `component` marker is `use-without-component`. The old names, `effect-await-without-task`, `yield-without-generator` and `use-without-context-effect`, are gone, with no alias.

`fetchCount` shows the form that is accepted: `async fn … -> Async<i32>` returns its value and the marker wraps it. A code that refuses something other than a missing marker keeps its own name. For example, an `await` inside an `iter` body is `iter-await`, and its hint names `async iter`.

Cells in this repository that bear on it: `modules/use/refused/src/cases/use_without_component`, `modules/decisions-taken/body_marker_whole_return_type-553/cells/marker_fn_forms`, `modules/decisions-taken/body_marker_whole_return_type-553/refused/src/cases/marker_type_mismatch`.

[draft/main.bp](draft/main.bp)
