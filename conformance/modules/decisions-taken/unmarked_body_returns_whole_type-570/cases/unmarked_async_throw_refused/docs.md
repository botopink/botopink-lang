# unmarked_async_throw_refused

The reference text this cell shows (from `conformance/docs.md`, § Effects — Body markers):

> An unmarked `-> Async<Result<T, E>>` body has no failure channel of its own:
> the `Result` is inside the task it returns whole, so its `throw` or
> propagating `try` is `effect-try-without-fallible-channel`, naming the
> marker.
