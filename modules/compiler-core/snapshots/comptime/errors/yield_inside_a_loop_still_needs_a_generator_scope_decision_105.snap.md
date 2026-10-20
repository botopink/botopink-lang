----- SOURCE CODE
async fn collected() -> Async<i32> {
    var n = 0;
    for ([1, 2, 3]) { x -> yield x * 2; };
    return n;
}

----- ERROR
error: yield-without-iter: `yield` needs a body marked `iter` or `async iter` — this body is marked `async`
  ┌─ main.bp:3:28
  │
3 │     for ([1, 2, 3]) { x -> yield x * 2; };
  │                            ^

  hint: A `yield` feeds the nearest generator scope: write `iter fn` (`async iter fn` for an `AsyncIter<T>`), or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
