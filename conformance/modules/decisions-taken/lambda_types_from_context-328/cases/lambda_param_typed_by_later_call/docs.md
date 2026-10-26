# lambda_param_typed_by_later_call

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A lambda is typed where it is written (decision 583): bound to a `val` with
> no annotation, it is typed by nothing, and a later call does not type it
> after the fact — `val later = { n -> … }` followed by `later(2)` is refused
> `lambda-untyped` at the lambda, a parameterless `{ -> … }` and a module-level
> `val` too.
