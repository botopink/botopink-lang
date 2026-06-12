----- SOURCE CODE
#[@result]
fn fetch() -> @Result<i32, string> {
    throw Result.Ok(42);
}

----- ERROR
error: result-throw-type-mismatch: a #[@result] fn raises E via `throw`; use `return` for the success variant.
  ┌─ :3:5
  │
3 │     throw Result.Ok(42);
  │     ^

  hint: If the value is the success payload, change `throw Result.Ok(<r>);` to `return <r>;`.
