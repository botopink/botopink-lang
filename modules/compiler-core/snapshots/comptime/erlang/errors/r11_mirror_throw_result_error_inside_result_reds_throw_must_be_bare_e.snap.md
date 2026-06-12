----- SOURCE CODE
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    throw Result.Error(error: "boom");
}

----- ERROR
error: throw-must-be-bare-E: a #[@result] fn must `throw` a value of type E; the @Result::Err wrapping is implicit.
  ┌─ :3:5
  │
3 │     throw Result.Error(error: "boom");
  │     ^

  hint: Drop the `Result.Error(...)` wrapping — write `throw <e>;` directly.
