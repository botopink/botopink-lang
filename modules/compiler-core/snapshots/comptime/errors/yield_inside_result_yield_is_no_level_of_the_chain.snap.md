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
#[@result]
fn bad(n: i32) -> @Result<i32, string> {
    yield n;
}

----- ERROR
error: yield-without-generator: `yield` needs a generator effect — `#[@generator]`, `#[@resultGenerator]` or `#[@futureGenerator]`; `#[@result]` is `@Result`, which does not
  ┌─ :15:5
  │
15 │     yield n;
  │     ^

  hint: A `yield` that is not inside a `loop (…) { … }` body is the function's: mark the fn `#[@resultGenerator]` (`-> @ResultGenerator<T>`), `#[@generator]` or `#[@futureGenerator]`.
