----- SOURCE CODE
fn collected() -> @Task<i32> {
    var n = 0;
    for ([1, 2, 3]) { x -> yield x * 2; };
    return n;
}

----- ERROR
error: yield-without-generator: `yield` needs `-> @Iterator<…>` or `-> @Stream<…>` return — this fn returns `@Task<…>`, which does not
  ┌─ main.bp:3:28
  │
3 │     for ([1, 2, 3]) { x -> yield x * 2; };
  │                            ^

  hint: A `yield` feeds the nearest generator scope: return `@Iterator<T>` (or `@Stream<T>`) from the fn, or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
