# decorator_random_float_unseeded

The reference text this cell shows (from `conformance/docs.md`, § Host bindings, std-wasm's seeded stream):

> Before any seed a wasm program's `seededFloat()`
> draws the host's entropy (`.RandomF64`'s); at comptime that draw is refused,
> located at the call that drew it, in a `comptime` expression or a decorator body
> alike (`comptime_random_float_unseeded`, `decorator_random_float_unseeded`) — a
> build has no entropy and never pretends to.

`drawn` calls `io.random.float()` unseeded: refused at that call, 11:13, not at the annotation `#[drawn]`.
