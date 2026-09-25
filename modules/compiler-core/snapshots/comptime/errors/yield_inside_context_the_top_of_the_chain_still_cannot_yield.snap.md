----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    return n;
}
#[@future]
fn fetch(n: i32) -> @Future<i32> {
    return n;
}
#[@context]
fn Bad(n: i32) -> Element {
    yield n;
}

----- ERROR
error: yield-without-generator: `yield` needs a generator effect — `#[@generator]`, `#[@resultGenerator]` or `#[@futureGenerator]`; `#[@context]` is `@Context`, which does not
  ┌─ :15:5
  │
15 │     yield n;
  │     ^

  hint: A `yield` feeds the nearest generator scope: mark the fn `#[@generator]` (`-> @Generator<T>`) or write the loop as `#[@generator] loop { … }` (decision 105).
