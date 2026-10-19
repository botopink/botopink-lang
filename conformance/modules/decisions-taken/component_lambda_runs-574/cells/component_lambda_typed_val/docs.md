# component_lambda_typed_val

The reference text this cell shows (from `conformance/docs.md`, § Effects — Body markers):

> A `{ component x -> … }` lambda is a `component fn` (decision 574): typed by
> the function type it is written for, `fn(x: T) -> Component<R>`, its body is
> a component body — it `use`s and `await`s, and its `return`s and its last
> expression answer `R` — and calling it only makes the component, which runs
> where it is rendered, with the scope it is rendered with. Its parameters and
> what it captures reach the body.
