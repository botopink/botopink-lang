# external_wasm_task_adapter_shape

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> An adapter answering `Async<T>` (decision 393) is declared over one type
> parameter and checked by **shape** at the annotation — the signature in the
> table, whatever `T` is — and the compiler makes the pending task the host's
> pollable backs:

`wasi: .Delay` is `(i32, T) -> Async<T>` over one type parameter; a declaration of another shape is refused at the annotation on every target.
