# declare_without_implementation_decorator

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> No bodyless declaration exists but two: one with `#[external(…)]`, and the
> compiler's own `declare val compiler` (decision 604). A decorator is no
> exception — its marker is a decorator with an empty body, so a bodyless one is
> refused at the declaration like any other.
