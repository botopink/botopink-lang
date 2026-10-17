# if_binding_before_loop_closure

The reference text this cell shows (from `conformance/docs.md`, § Narrowing):

> The binder of `if (x) { v -> … }` (and of `x ?? d`, which reads as one) is bound in the then-branch
> alone: a later closure — a `for` body — that binds the same name in its own `if` reads its own
> binding, never the earlier one, whether the earlier optional was present or absent:
