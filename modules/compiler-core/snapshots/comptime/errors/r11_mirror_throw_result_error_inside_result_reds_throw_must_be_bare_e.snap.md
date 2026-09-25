----- SOURCE CODE
fn parse(n: i32) -> @Result<i32, string> {
    throw Result.Error(error: "boom");
}

----- ERROR
error: throw-must-be-bare-E: a body whose return carries `@Result<R, E>` must `throw` a value of type E; the @Result::Err wrapping is implicit.
  ┌─ :2:5
  │
2 │     throw Result.Error(error: "boom");
  │     ^

  hint: Drop the `Result.Error(...)` wrapping — write `throw <e>;` directly.
