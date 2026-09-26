----- SOURCE CODE
fn fetch() -> @Result<i32, string> {
    return Result.Error("boom");
}

----- ERROR
error: result-return-type-mismatch: a body whose return carries `@Result<R, E>` returns R via `return`; use `throw` for the error variant.
  ┌─ main.bp:2:5
  │
2 │     return Result.Error("boom");
  │     ^

  hint: If the value is an error, change `return Result.Error(<e>);` to `throw <e>;`.
