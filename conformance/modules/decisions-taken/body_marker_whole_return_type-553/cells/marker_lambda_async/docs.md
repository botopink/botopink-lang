# marker_lambda_async

The reference text this cell shows (from `conformance/docs.md`, § Effects — Body markers):

> Inside a lambda's brace, before the parameters, the marker makes a marked lambda —
> `{ async x -> … }`, `{ iter n -> … }`, `{ async iter n -> … }` — and before `fn(…)` a marked
> function expression; `async {` is always the block form and `iter loop {` the loop. A marked lambda is typed by the function type it
> is written for (decision 147): an annotated `val`, a parameter. Its body is a
> function body — `return v` is the iterator's `R`, a top-level `continue` is
> refused `continue-outside-loop`, `break v` is refused (decision 584 (2)).
