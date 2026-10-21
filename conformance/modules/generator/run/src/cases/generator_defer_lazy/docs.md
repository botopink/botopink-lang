# generator_defer_lazy

The reference text this cell shows (from `conformance/docs.md`, § Iterators and streams):

> Nothing of the body runs before the first `next`, and nothing past the `yield` that
> answered the last one: a print before and after a `yield` comes out between the
> items, and an endless generator is consumed by `take(n)` — on every form, an
> `iter fn`, an `iter loop` and a marked lambda `{ iter -> … }`.
