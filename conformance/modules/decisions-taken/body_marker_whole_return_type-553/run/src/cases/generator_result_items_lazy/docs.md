# generator_result_items_lazy

The reference text this cell shows (from `conformance/docs.md`, § Iterators and streams):

> Nothing of the body runs before the first `next`, and nothing past the `yield` that
> answered the last one: a print before and after a `yield` comes out between the
> items, and an endless generator is consumed by `take(n)` — on every form, an
> `iter fn`, an `iter loop` and a marked lambda `iter { -> … }`.

> **Items that can fail — `Iter<Result<T, E>>`.** The iterator does not
> fail; **each item** may be an error. When the item is `Result<U, E>` the body
> gains the sugar: `yield v` with `v: U` emits `Ok(v)` (with `v: Result<U, E>` it
> emits it as is), `throw e` emits `Error(e)` and ends, and a `try x` that fails
> emits `Error(e)` and ends.
