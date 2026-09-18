----- SOURCE CODE
#[@future]
fn fetch() -> @Future<i32, string> {
    throw Future.rejected(error: "boom");
}

----- ERROR
error: future-throw-must-be-bare-E: a #[@future] fn must `throw` a value of type E; the @Future.rejected wrapping is implicit.
  ┌─ :3:5
  │
3 │     throw Future.rejected(error: "boom");
  │     ^

  hint: Drop the `Future.rejected(...)` wrapping — write `throw <e>;` directly.
