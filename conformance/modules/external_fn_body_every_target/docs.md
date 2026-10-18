# external_fn_body_every_target

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A private fn binds a declaration on every target** (decisions 238, 263, 305). On
> `.JavaScript` and `.Erlang` (which the beam target reads) the
> labelled cell `fn: <name>` (`#[@external(.Erlang(body: powBody))]`) binds what
> wasm's `fn: <name>` cell binds — a private `fn` of the same module, with a body, taking the same
> parameter types in the same order and answering the same type — and it is
> checked the same way, at the annotation. One algorithm written in botopink then
> answers the same bits on every target, instead of each host's own library
> (`std/math`'s `sin`, `pow`, … run std's bodies on erlang and beam, and `pow` on
> commonJS too).
