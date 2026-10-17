----- SOURCE CODE
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn parse(n: i32) -> @Result<i32, string> {
    return n;
}
fn fetch(n: i32) -> @Task<i32> {
    return n;
}
fn bad(n: i32) -> @Result<i32, string> {
    yield n;
}

----- ERROR
error: yield-without-iter: `yield` needs `-> @Iterator<…>` or `-> @Stream<…>` return — this fn returns `@Result<…>`, which does not
  ┌─ main.bp:12:5
  │
12 │     yield n;
  │     ^

  hint: A `yield` feeds the nearest generator scope: write `iter fn` (`async iter fn` for a `@Stream<T>`), or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
