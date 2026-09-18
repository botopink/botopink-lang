----- SOURCE CODE
#[@future]
fn fetch() -> @Future<i32, string> {
    return Future.resolved(value: 42);
}

----- ERROR
error: future-return-must-be-bare-T: a #[@future] fn must `return` a value of type T; the @Future.resolved wrapping is implicit.
  ┌─ :3:5
  │
3 │     return Future.resolved(value: 42);
  │     ^

  hint: Drop the `Future.resolved(...)` wrapping — write `return <t>;` directly.
