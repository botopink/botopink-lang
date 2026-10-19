----- SOURCE CODE
val Element = type() implement Renderable
fn state(initial: i32) -> Component<i32> {
    return initial;
}
fn parse(n: i32) -> Result<i32, string> {
    return n;
}
fn fetch(n: i32) -> Async<i32> {
    return n;
}
fn Bad(n: i32) -> Component<Element> {
    yield n;
}

----- ERROR
error: yield-without-iter: `yield` needs `-> @Iter<…>` or `-> @AsyncIter<…>` return — this fn returns `@Component<…>`, which does not
  ┌─ main.bp:12:5
  │
12 │     yield n;
  │     ^

  hint: A `yield` feeds the nearest generator scope: write `iter fn` (`async iter fn` for a `@AsyncIter<T>`), or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
