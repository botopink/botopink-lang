----- SOURCE CODE
fn fetch() -> @Result<i32, string> {
    return Result.Ok(42);
}

----- ERROR
error: return-must-be-bare-R: a body whose return carries `@Result<R, E>` must `return` a value of type R; the @Result::Ok wrapping is implicit.
  ┌─ main.bp:2:5
  │
2 │     return Result.Ok(42);
  │     ^

  hint: Drop the `Result.Ok(...)` wrapping — write `return <r>;` directly.
