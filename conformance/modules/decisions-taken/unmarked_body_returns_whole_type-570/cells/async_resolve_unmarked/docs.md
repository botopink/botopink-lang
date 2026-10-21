# async_resolve_unmarked

The reference text this cell shows (from `conformance/docs.md`, § Effects — Body markers):

> Without a marker a body is an ordinary function and returns the whole type
> (decision 570): an unmarked `-> Async<T>` body returns an `Async<T>` —
> `Async.resolve(v)`, std's settled task, or a call that answers one — and a
> caller awaits it as it awaits an `async fn`.
