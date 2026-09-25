----- SOURCE CODE
fn bad() -> @Future<i32> {
    return 0;
}

----- ERROR
error: a function returning `@Future`/`@ResultGenerator`/`@FutureGenerator` needs an effect annotation
  ┌─ :2:5
  │
2 │     return 0;
  │     ^

  hint: Mark it `#[@future]` / `#[@resultGenerator]` / `#[@futureGenerator]`.
