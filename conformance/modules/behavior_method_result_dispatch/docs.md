# behavior_method_result_dispatch

The reference text this cell shows (from `conformance/docs.md`, § Results):

> A method declared `-> @Result` is a function like any other (decision 304): a record's and an
> enum's method, and a behavior's method dispatched through a parameter typed by the behavior —
> its `default fn` included — answer `Ok(v)` for `return v` and `Error(e)` for `throw e`, and their
> `try` propagates, on every target:
