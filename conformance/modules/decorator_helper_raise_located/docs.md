# decorator_helper_raise_located

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A body declared in the annotated module that raises is refused at the call that
> raised (decisions 451 (3), 532) — the innermost call the raise leaves, in the
> body or in a function the body calls, of this module or another — and each call
> of the chain is a `called from` line, down to the annotation that ran the body
> (``called from src/main.bp:13:13``, ``called from src/main.bp:17:3``):

`short` calls `requireShort`, whose `panic` raises: refused at that `panic`, 8:28, with the helper's call in the body (13:13) and the annotation `#[short]` (17:3) as the `called from` lines.
