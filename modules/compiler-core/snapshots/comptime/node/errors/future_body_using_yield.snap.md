----- SOURCE CODE
#[@future]
fn bad() -> @Future<i32> {
    yield 1;
}

----- ERROR
error: `yield` can only be used inside a `#[@generator]` / `#[@iterator]` / `#[@asyncGenerator]` fn
  ┌─ :3:5
  │
3 │     yield 1;
  │     ^

  hint: A `#[@future]` fn awaits; mark the fn `#[@iterator]` (`-> @Iterator<T>`) to yield.
