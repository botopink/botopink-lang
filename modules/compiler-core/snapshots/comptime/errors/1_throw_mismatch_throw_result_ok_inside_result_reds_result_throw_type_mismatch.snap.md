----- SOURCE CODE
fn fetch() -> @Result<i32, string> {
    throw Result.Ok(42);
}

----- ERROR
error: result-throw-type-mismatch: a body whose return carries `@Result<R, E>` raises E via `throw`; use `return` for the success variant.
  ┌─ main.bp:2:5
  │
2 │     throw Result.Ok(42);
  │     ^

  hint: If the value is the success payload, change `throw Result.Ok(<r>);` to `return <r>;`.
