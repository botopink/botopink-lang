----- SOURCE CODE
val Element = type implement @Context<Element> { }
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn parse(n: i32) -> @Result<i32, string> {
    return n;
}
fn fetch(n: i32) -> @Task<i32> {
    return n;
}
fn Bad(n: i32) -> @Component<Element, Element> {
    yield n;
}

----- ERROR
error: yield-without-generator: `yield` needs `-> @Iterator<…>` or `-> @Stream<…>` return — this fn returns `@Component<…>`, which does not
  ┌─ :12:5
  │
12 │     yield n;
  │     ^

  hint: A `yield` feeds the nearest generator scope: return `@Iterator<T>` (or `@Stream<T>`) from the fn, or write the loop as `iter loop { … }` (decision 125). To collect in a plain fn, use `map` / `filter` or a `var`.
