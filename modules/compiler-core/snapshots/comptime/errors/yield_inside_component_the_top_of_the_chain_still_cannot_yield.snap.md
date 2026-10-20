----- SOURCE CODE
val Element = type() implement Renderable
component fn state(initial: i32) -> Component<i32> {
    return initial;
}
fn parse(n: i32) -> Result<i32, string> {
    return n;
}
async fn fetch(n: i32) -> Async<i32> {
    return n;
}
component fn Bad(n: i32) -> Component<Element> {
    yield n;
}

----- ERROR
error: yield-without-iter: `yield` needs a body marked `iter` or `async iter` — this body is marked `component`
  ┌─ main.bp:12:5
  │
12 │     yield n;
  │     ^

  hint: A `yield` feeds the nearest generator scope: write `iter fn` (`async iter fn` for an `AsyncIter<T>`), or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
