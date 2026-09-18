----- SOURCE CODE
fn bad() -> @Result<i32, string> {
    @todo();
}

----- ERROR
error: effect-missing-annotation: a function returning `@Result<D, E>` needs `#[@result]`
  ┌─ :2:5
  │
2 │     @todo();
  │     ^

  hint: Mark it `#[@result]`: `return` then carries the success value and `throw` the error channel's own (decision 8 § 9). Without the annotation the wrapper is not built.
