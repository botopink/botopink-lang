# iterator_result_items_handled

The reference text this cell shows (from `conformance/docs.md`, § Iterators and streams):

> **Items that can fail — `Iterator<Result<T, E>>`.** The iterator does not
> fail; **each item** may be an error. When the item is `Result<U, E>` the body
> gains the sugar: `yield v` with `v: U` emits `Ok(v)` (with `v: Result<U, E>` it
> emits it as is), `throw e` emits `Error(e)` and ends, and a `try x` that fails
> emits `Error(e)` and ends. Whoever iterates receives the `Result` and decides —
> **`for` does no implicit `try`**:
