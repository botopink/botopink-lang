# defer_refuses_try

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> A `try` in a `defer` body whose region is not written inside the body would propagate the failure
> out of the deferred code; it is refused `defer-try`, located. A `try … catch` region written in the
> body is handled there (decision 866).
