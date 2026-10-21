# Decision 950 — (a): the collection loop is `for x in xs { … }` and `for await x in s { … }` — a binder before `in`, the body a block —; `for x in try xs` consumes an iterator whose end is a `Result` (553 (3)); 105's `for (xs) { x -> … }` and `for await (s) { x -> … }` go; amends 105.

`for_in_loop` walks a collection, an exclusive and an inclusive range, an `Iter` and, with `for await`, an
`AsyncIter`; a tuple pattern binds as a `val` binds it, `_` binds nothing, a label after the keyword is reached by
`continue :outer` and `break :outer`, and `for n in try parsed(ok)` propagates the `Result` the iterable answers. It
prints the same lines on the four targets. `for_parenthesised_refused` writes 105's `for (xs) { x -> … }`, refused
`for-parenthesised` at its `(`, naming the new form.

The end of an iteration as a `Result` (`Iter<T, Result<V, E>>`, 553 (3)) is 553's third piece; until it lands
`for x in try e` reads the `Result` the iterable expression answers.

[cells/for_in_loop/src/main.bp](cells/for_in_loop/src/main.bp)

[cells/for_parenthesised_refused/src/main.bp](cells/for_parenthesised_refused/src/main.bp)
