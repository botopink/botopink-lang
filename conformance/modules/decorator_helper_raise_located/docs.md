# decorator_helper_raise_located

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A body declared in the annotated module that raises is refused at the call that
> raised (decision 451 (3)) — the innermost of this module's calls the raise
> leaves, in the body or in a function of the module the body calls — and the
> hint names the annotation that ran the body as its frame (``raised by this call
> while `#[short]` (at 17:3) ran the decorator's body``):

`short` calls `requireShort`, whose `@panic` raises: refused at that `@panic`, 8:28 — not at the helper's call in the
body, not at `#[short]`.
