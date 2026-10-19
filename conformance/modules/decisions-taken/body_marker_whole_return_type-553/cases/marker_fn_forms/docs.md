# marker_fn_forms

The reference text this cell shows (from `conformance/docs.md`, § Effects — Body markers):

> A body that compiles specially carries a marker (decision 553): `async` (its
> body may `await`), `iter` (`yield`), `async iter` (`yield` and `await`) and
> `component` (`use`, `await`), written right before `fn` — `[#[…]] [pub]
> [default] <marker> fn` — on a declaration, a type's method, a behavior's
> `default fn` and an implement's method, and the return type is the wrapper
> the marker names. The marked body answers what the same body answers
> unmarked.
