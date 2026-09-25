----- SOURCE CODE
#[@future]
fn bad() -> @Future<i32> {
    yield 1;
}

----- ERROR
error: yield-without-generator: `yield` needs a generator effect — `#[@generator]`, `#[@resultGenerator]` or `#[@futureGenerator]`; `#[@future]` is `@Future`, which does not
  ┌─ :3:5
  │
3 │     yield 1;
  │     ^

  hint: A `yield` feeds the nearest generator scope: mark the fn `#[@generator]` (`-> @Generator<T>`) or write the loop as `#[@generator] loop { … }` (decision 105).
