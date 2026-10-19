# Decision 571 — A marker is for a body: a declaration without one never carries it

The example has two functions with no body. `delay` is a host binding, a `declare fn` with `#[compiler.external(…)]`. It writes only its return type, `Async<i32>`, and is accepted. `Clock.now` is a behavior's abstract member written with `async` in front, and that marker is refused at the marker, `marker-on-declaration`, with the label "remove the marker". A marker says how a body is compiled, and these functions have none. `Fixed`, which implements `Clock`, does mark its own `now`, because its body is the one being compiled.

Cells in this repository that also bear on it: `modules/decisions-taken/body_marker_whole_return_type-553/refused/src/cases/marker_on_declaration`.

[draft/main.bp](draft/main.bp)
