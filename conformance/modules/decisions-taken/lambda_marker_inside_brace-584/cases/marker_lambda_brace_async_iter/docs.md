# marker_lambda_brace_async_iter

The reference text this cell shows (from `conformance/docs.md`, § Effects — Body markers):

> A lambda writes its marker inside the brace, before the parameters (decision
> 584): `{ async x -> … }`, `{ iter -> … }`, `{ async iter x -> … }`, `{
> component -> … }`; before `fn(…)` the marker makes a marked function
> expression. A marked lambda is typed by the function type it is written for
> (decision 147): an annotated `val`, a parameter. It goes wherever a lambda
> goes, the trailing form included — `apply(5) { async x -> … }`.
