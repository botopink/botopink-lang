----- SOURCE CODE
fn nums() -> @Result<i32, string, i32> {
    return 1;
}

----- ERROR
error: generic-arg-count-exceeded: `@Result` takes at most 2 type arguments, 3 given
  ┌─ :1:14
  │
1 │ fn nums() -> @Result<i32, string, i32> {
  │              ^

  hint: Drop the extra type argument: the wrapper declares no channel for it.
