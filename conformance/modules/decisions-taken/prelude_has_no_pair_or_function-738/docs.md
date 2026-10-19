# Decision 738 — (c), a third option: neither `Pair<A, B>` nor `Function` exists — a pair is the tuple `#(A, B)`, and the function combinators are plain functions of a std module.

The example builds a pair as the tuple `#(1, "x")`. `p._1` reads its second element and `val #(n, _) = p` takes the first apart. The function combinators are plain functions of std's `functions` module, imported by path: `compose(inc, double)` is an ordinary function value applied to `n`. Neither `Pair` nor `Function` exists, so `Pair.of(1, "x")` on the last line is refused at `Pair`, the message naming the tuple `#(A, B)`. The function type is `fn(A) -> B`, lowercase, like every other non-contract type.

Cells in this repository that bear on it: `modules/decisions-taken/prelude_is_primitives-606/cases/prelude_name_bare`, `modules/decisions-taken/prelude_is_primitives-606/cases/prelude_name_shadowed`.

[draft/main.bp](draft/main.bp)
