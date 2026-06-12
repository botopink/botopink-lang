----- SOURCE CODE
fn bad() -> @Future<i32> {
    return 0;
}

----- ERROR
error: a function returning `@Future`/`@Iterator`/`@AsyncIterator` needs an effect annotation
  ┌─ :2:5
  │
2 │     return 0;
  │     ^

  hint: Mark it `#[@future]` / `#[@iterator]` / `#[@asyncGenerator]` (or use the deprecated `*fn`).
