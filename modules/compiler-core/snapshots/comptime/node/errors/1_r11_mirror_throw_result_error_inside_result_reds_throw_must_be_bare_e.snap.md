----- SOURCE CODE
#[@result]
fn fetch() -> @Result<i32, string> {
    throw Result.Error("boom");
}

----- ERROR
error: throw-must-be-bare-E: a #[@result] fn must `throw` a value of type E; the @Result::Err wrapping is implicit.
  ┌─ :3:5
  │
3 │     throw Result.Error("boom");
  │     ^

  hint: Drop the `Result.Error(...)` wrapping — write `throw <e>;` directly.
