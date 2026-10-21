# tuple_destructure_discard

Decision 738: a pair is the tuple `#(A, B)`, read by `p._0` / `p._1` or by `val #(a, _) = p`. A `_` member of a tuple
pattern reads nothing and binds nothing — in a `val` and in a parameter alike, and as often as it is written. It used to
be a parse error at the `_`. It prints `1`, `7`, `3` and `x`.
