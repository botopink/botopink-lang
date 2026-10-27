# Decision 276 — jhonstart declares `pub type View = @Component<Element>;` (354) in `element.bp` — a type alias (decision 110), the same

`View` is declared `pub type View = Component<Element>;` — a type alias, the same type under a shorter name, which is
how `rakun-bpp` declares it. So each spelling accepts the other: `Card` answers a `View` and `Badge` a
`Component<Element>`, and `both` takes a `Badge(…)` where it declared a `View` and a `Card(…)` where it declared a
`Component<Element>`, answering a `View[]` holding both. No subtyping is involved and nothing converts: the emitted code
keeps the full type, and a decorator that checks a component's return compares the resolved type, never the text.
`run` renders each component from the root scope and prints `badge new` and `card home`.

Cells that also bear on it: `modules/decisions-taken/component_is_lambda_over_render_scope-388/cells/component_run_root`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/component_hook_and_component`.

[draft/main.bp](draft/main.bp)
