----- SOURCE CODE
fn bad() -> Async<i32> {
    yield 1;
}

----- ERROR
error: yield-without-iter: `yield` needs `-> @Iter<…>` or `-> @AsyncIter<…>` return — this fn returns `@Async<…>`, which does not
  ┌─ main.bp:2:5
  │
2 │     yield 1;
  │     ^

  hint: A `yield` feeds the nearest generator scope: write `iter fn` (`async iter fn` for a `@AsyncIter<T>`), or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
