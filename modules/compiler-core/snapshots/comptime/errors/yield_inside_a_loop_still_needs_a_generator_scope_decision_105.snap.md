----- SOURCE CODE
fn collected() -> Async<i32> {
    var n = 0;
    for ([1, 2, 3]) { x -> yield x * 2; };
    return n;
}

----- ERROR
error: yield-without-iter: `yield` needs `-> @Iter<…>` or `-> @AsyncIter<…>` return — this fn returns `@Async<…>`, which does not
  ┌─ main.bp:3:28
  │
3 │     for ([1, 2, 3]) { x -> yield x * 2; };
  │                            ^

  hint: A `yield` feeds the nearest generator scope: write `iter fn` (`async iter fn` for a `@AsyncIter<T>`), or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
