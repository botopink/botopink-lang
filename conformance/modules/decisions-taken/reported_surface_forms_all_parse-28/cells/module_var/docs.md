# module_var

The reference text this cell shows (from `conformance/docs.md`, § var — mutable binding):

> A `var` may be reassigned. Inside a `fn` it is a local; at module level it is
> **one value per execution context** — the whole program on commonJS and wasm,
> the **process** on erlang and beam. Two writes through a `fn` and one read
> print `2`:
