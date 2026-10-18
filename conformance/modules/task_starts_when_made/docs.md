# task_starts_when_made

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> `std/io/random`'s seeded stream is std-wasm's (decision 451), bound by the
> `std:` cells on `seed` and `seededFloat`: Mulberry32 as the commonJS sidecar
> draws it, so a seed gives the same draws there, in a wasm program and at
> comptime on every target. Before any seed a wasm program's `seededFloat()`
> draws the host's entropy (`random_f64`'s); at comptime that draw is refused,
> located — a build has no entropy and never pretends to.
>
> An adapter answering `Task<T>` (decision 393) is declared over one type
> parameter and checked by **shape** at the annotation — the signature in the
> table, whatever `T` is — and the compiler makes the pending task the host's
> pollable backs:
