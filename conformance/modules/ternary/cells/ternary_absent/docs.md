# ternary_absent

The reference text this cell shows (from `conformance/docs.md`, § Decided, not yet implemented):

> These forms are **deliberately absent**, so that none reads as unfinished work:
>
> | Form | What the compiler says |
> |---|---|
> | `c ? a : b` | `error[ternary-absent]` — `if` is an expression: `val x = if (c) { a } else { b };` |
