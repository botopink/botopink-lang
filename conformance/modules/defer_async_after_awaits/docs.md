# defer_async_after_awaits

The reference text this cell shows (from `conformance/docs.md`, § Blocks):

> In an `async` body a `defer` runs when the task's body ends, after its awaits; in a `Stream` when
> the stream ends or its consumer stops (a `break` in `for await`):
