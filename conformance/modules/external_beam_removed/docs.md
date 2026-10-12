# external_beam_removed

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> `inline: true`, written last on `External.Erlang`, opts the declaration out of
> the dispatch table so the backend's hand-coded shape keeps emitting. That
> variant alone declares it, because the erlang and beam emitters, which both
> read `External.Erlang`, alone read it. Written on `Node`, `Wasm` or
> `Typescript`, anywhere but last, or with a value that is not a bool, it would
> be a switch nothing reads, so it is refused at the annotation (`` `External.Node`
> declares no `inline` — the flag is read by the erlang and beam emitters from
> `External.Erlang` only ``).
>
> One annotation binds the BEAM: `External.Erlang` serves the erlang and the beam
> targets, the same VM and the same OTP calls (decision 437). `@External.Beam` is
> gone; writing it is a located error at the annotation naming the form in force,
> never an alias.
