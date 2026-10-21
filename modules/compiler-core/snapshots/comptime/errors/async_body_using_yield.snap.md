----- SOURCE CODE
async fn bad() -> Async<i32> {
    yield 1;
}

----- ERROR
error: yield-without-iter: `yield` needs a body marked `iter` or `async iter` — this body is marked `async`
  ┌─ main.bp:2:5
  │
2 │     yield 1;
  │     ^

  hint: A `yield` feeds the nearest generator scope: write `iter fn` (`async iter fn` for an `AsyncIter<T>`), or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
