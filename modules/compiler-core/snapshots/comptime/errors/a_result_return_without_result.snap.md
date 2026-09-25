----- SOURCE CODE
fn bad() -> @Result<i32, string> {
    @todo();
}

----- ERROR
error: effect-missing-annotation: @Result needs #[@result] — a function returning `@Result<D, E>` declares its effect
  ┌─ :1:13
  │
1 │ fn bad() -> @Result<i32, string> {
  │             ^

  hint: Mark it `#[@result]`: `return` then carries the success value and `throw` the error channel's own (decision 8 § 9). Without the annotation the wrapper is not built.
