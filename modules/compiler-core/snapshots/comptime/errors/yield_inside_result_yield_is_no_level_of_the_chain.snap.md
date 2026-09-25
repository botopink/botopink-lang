----- SOURCE CODE
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Component<Element, i32> {
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
#[@result]
fn bad(n: i32) -> @Result<i32, string> {
    yield n;
}

----- ERROR
error: yield-without-generator: `yield` needs a generator effect — `#[@generator]`, `#[@resultGenerator]` or `#[@futureGenerator]`; `#[@result]` is `@Result`, which does not
  ┌─ :16:5
  │
16 │     yield n;
  │     ^

  hint: A `yield` feeds the nearest generator scope: mark the fn `#[@generator]` (`-> @Generator<T>`) or write the loop as `#[@generator] loop { … }` (decision 105).
