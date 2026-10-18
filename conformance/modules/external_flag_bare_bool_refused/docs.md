# external_flag_bare_bool_refused

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **Only the template is positional** (decisions 487, 621): in a cell of
> `Implementation` every other field — `body:`, `result:` on every variant,
> `inline:` on `.Erlang`, and on `.Wasm` `op:`, `std:`, `wasi:`, `host:`,
> `needs:` — is written by its label, in any order among the arguments
> (`.Erlang(result: true, "json:decode($0)")` is `.Erlang("json:decode($0)",
> result: true)`). A second unlabelled argument is refused at the argument,
> naming the label to write — the one its value fits (`body:` for a name,
> `result:` for a `bool`, and `inline:` beside it on `.Erlang`), else the labels
> the variant has:
