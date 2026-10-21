# tuple_literal_label

The reference text this cell shows (from `conformance/docs.md`, § Decided, not yet implemented):

> These forms are **deliberately absent**, so that none reads as unfinished work:
>
> | Form | What the compiler says |
> |---|---|
> | `#(x: 1, y: 2)` | `error[tuple-literal-label]` — a tuple literal is positional, `#(1, 2)`; labels belong to the tuple type, `#(x: i32, y: i32)` |
