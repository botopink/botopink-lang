----- SOURCE CODE
fn bad() -> @Task<i32> {
    yield 1;
}

----- ERROR
error: yield-without-generator: `yield` needs `-> @Iterator<…>` or `-> @Stream<…>` return — this fn returns `@Task<…>`, which does not
  ┌─ main.bp:2:5
  │
2 │     yield 1;
  │     ^

  hint: A `yield` feeds the nearest generator scope: return `@Iterator<T>` (or `@Stream<T>`) from the fn, or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
