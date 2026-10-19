# generic_thunk_result_binds

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> A generic function over a thunk answering a task — `work: fn() -> Async<Result<T,
> E>>`, std's `async.retry` — binds `T` and `E` from the thunk's answer, in its own
> module or another, and so does the generic it passes the thunk on to:
