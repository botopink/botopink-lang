----- SOURCE CODE
fn fetch() -> @Result<i32, string> {
    throw Result.Error("boom");
}

----- ERROR
error: throw-must-be-bare-E: a body whose return carries `@Result<R, E>` must `throw` a value of type E; the @Result::Err wrapping is implicit.
  ┌─ :2:5
  │
2 │     throw Result.Error("boom");
  │     ^

  hint: Drop the `Result.Error(...)` wrapping — write `throw <e>;` directly.
