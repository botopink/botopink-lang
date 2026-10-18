# external_fn_body_every_target

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> **A private fn binds a declaration on a target** (decisions 238, 263, 305, 610). On
> `.JavaScript` and `.Erlang` (which the beam target reads) the
> labelled cell `body: <name>` (`#[compiler.external(.Erlang(body: sinBody))]`) binds what
> wasm's `body: <name>` cell binds — a private `fn` of the same module, with a body, taking the same
> parameter types in the same order and answering the same type — and it is
> checked the same way, at the argument. One algorithm written in botopink then
> answers the same bits on the targets that name it, instead of each host's own
> library (`std/math`'s `sin`, … run std's bodies on erlang and beam, beside
> V8's `Math.*` on commonJS).
