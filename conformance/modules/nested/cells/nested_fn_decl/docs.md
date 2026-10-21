# nested_fn_decl

The reference text this cell shows (from `conformance/docs.md`, § Decided, not yet implemented):

> These forms are **deliberately absent**, so that none reads as unfinished work:
>
> | Form | What the compiler says |
> |---|---|
> | `fn inner(…) { … }` inside a body | `error[nested-fn-decl]` — inside a body a function is a value: `val inner = { x -> … };` |
