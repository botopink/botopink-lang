# external_result_on_fn_cell

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> The flag has one reading, so the checker holds it to it, at the annotation
> (decisions 487, 488, 490, 491):
>
> - `result:` belongs to a host call that can fail: beside an `fn:` cell (a
>   botopink function, which fails only through its own `Result`) or an `op:`
>   cell (a wasm instruction) it is refused:
