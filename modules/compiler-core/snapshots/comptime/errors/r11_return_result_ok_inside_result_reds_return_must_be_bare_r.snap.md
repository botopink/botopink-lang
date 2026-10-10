----- SOURCE CODE
fn parse(n: i32) -> @Result<i32, string> {
    return Result.Ok(result: n * 2);
}

----- ERROR
error: return-must-be-bare-R: a body whose return carries `@Result<R, E>` must `return` a value of type R; the @Result::Ok wrapping is implicit.
  ┌─ main.bp:2:5
  │
2 │     return Result.Ok(result: n * 2);
  │     ^

  hint: Drop the `Result.Ok(...)` wrapping — write `return <r>;` directly.
