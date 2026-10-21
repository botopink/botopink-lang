# narrow_after_null_return

The reference text this cell shows (from `conformance/docs.md`, § Narrowing):

> | Shape | Where the name is narrowed |
> |---|---|
> | `if (x is T) { … }` | the branch |
> | `if (guard(x)) { … }`, for a `fn guard(x: …) -> x is T` | the branch |
> | `if (x != null) { … }` — and `null != x` | the branch, to the `?T`'s payload |
> | `if (x == null) { … } else { … }` | the `else` branch |
> | `if (x == null) { return …; }` — a guard clause | the REST of the block, for a `val` |
> | `if (a != null && b != null)` | both names, in the branch |
> | `if (a == null \|\| b == null) { return …; }` | both names, below the guard |
> | `if (x) { v -> … }` | `v` is the payload; `x` itself is untouched |
> | `case x { null { … } _ { … x! … } }` | the value is read `x!` |
