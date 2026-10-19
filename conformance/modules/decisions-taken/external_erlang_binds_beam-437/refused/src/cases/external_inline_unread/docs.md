# external_inline_unread

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> `inline: true` on `.Erlang` opts the declaration out of the dispatch
> table so the backend's hand-coded shape keeps emitting. That variant alone
> declares it, because the erlang and beam emitters, which both read
> `.Erlang`, alone read it. Written on `JavaScript` or `Wasm`, or
> with a value that is not a bool, it would be a switch nothing reads, so it is
> refused at the annotation (`` `.JavaScript` declares no `inline` — the flag is
> read by the erlang and beam emitters from `.Erlang` only ``).
