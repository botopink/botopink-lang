# task_result_rejects

The reference text this cell shows (from `conformance/docs.md`, § Tasks):

> Every way a failing task reaches an `await` reads the same on every target —
> a function or a method that throws, a task handed over whole, generic code
> awaiting an `Async<T>`, tasks started before either is awaited, an
> `async { }` block that throws:
