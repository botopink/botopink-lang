# loop_forms

The reference text this cell shows (from `conformance/docs.md`, § Loops):

> A plain loop is a statement: bare `break` leaves it and `continue` starts its
> next round, in all three. `for` binds the item only — the index is
> `for i in 0..xs.length { … }`. The parentheses stay (`while (cond) {`), as
> they do on `if`: without them `while x {` could not tell the body from a record
> literal. `loop (…)` is an error naming `for` and `while`.
>
> A range `a..b` excludes its end and `a...b` includes it: `for (1..4)` visits
> `1 2 3`, `for (1...4)` visits `1 2 3 4`. A range is not a value — there is no
> `Range` and no `.rev()`; a countdown is a `while` or `xs.reverse()`.
