# external_body_not_a_fn

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **The `body:` cell's rule** (decision 610), beside `op:`, `std:` and `wasi:`'s:
> `body:` is the one name of the botopink-body cell, on `.Erlang`,
> `.JavaScript` and `.Wasm` alike, and the template is optional only beside it.
> `body:` is a bare identifier naming a private bodied `fn` of the same module
> whose parameters and return are the declaration's; anything else — `body:
> "x"`, `body: 1`, a `pub` or bodiless function, other types — is refused at the
> argument, `external-body-not-a-fn`:
