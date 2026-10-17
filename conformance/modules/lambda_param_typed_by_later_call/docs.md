# lambda_param_typed_by_later_call

The reference text this cell shows (from `conformance/docs.md`, § Lambdas and method chains):

> A lambda bound with no annotation takes its parameters' types from the calls
> that use it: `val later = { n -> async { … n.toString() … } }` called as
> `later(2)` types `n` as `i32`, and `n.toString()` is `i32`'s method on every
> target.
