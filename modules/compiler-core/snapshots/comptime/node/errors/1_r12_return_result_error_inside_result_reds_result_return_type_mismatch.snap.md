----- SOURCE CODE
#[@result]
fn fetch() -> @Result<i32, string> {
    return Result.Error("boom");
}

----- ERROR
error: result-return-type-mismatch: a #[@result] fn returns R via `return`; use `throw` for the error variant.
  ┌─ :3:5
  │
3 │     return Result.Error("boom");
  │     ^

  hint: If the value is an error, change `return Result.Error(<e>);` to `throw <e>;`.
