# defer_try_catch_inside

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> A `try … catch` region written in a `defer` body is handled there, so the body does not propagate
> (decision 866): the failure of `fails()` is caught by the `catch` inside the deferred code.
