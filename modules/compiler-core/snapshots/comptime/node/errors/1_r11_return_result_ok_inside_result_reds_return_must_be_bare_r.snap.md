----- SOURCE CODE
#[@result]
fn fetch() -> @Result<i32, string> {
    return Result.Ok(42);
}

----- ERROR
error: return-must-be-bare-R: a #[@result] fn must `return` a value of type R; the @Result::Ok wrapping is implicit.
  ┌─ :3:5
  │
3 │     return Result.Ok(42);
  │     ^

  hint: Drop the `Result.Ok(...)` wrapping — write `return <r>;` directly.
