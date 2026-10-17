# iterator_yield_break

The reference text this cell shows (from `conformance/docs.md`, § Iterators and streams):

> An iterator produces a sequence on demand: each `next` runs the body up to the
> next `yield`. A stream is the same, asynchronous — finding out whether there is
> a next item may need waiting. Both answer one step type (decision 122):
> `YieldStep<T>` = `{ Yield(value: T), Done }`.
>
> - `yield v` emits `v` and **continues**;
> - `break v` emits `v` and **ends** (≡ `yield v; break;`);
> - a bare `break` outside any inner loop ends without emitting.
