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

  hint: A `yield` that is not inside a `loop (…) { … }` body is the function's: mark the fn `#[@resultGenerator]` (`-> @ResultGenerator<T>`), `#[@generator]` or `#[@futureGenerator]`.
