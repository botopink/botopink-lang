----- SOURCE CODE
#[@result]
#[@future]
fn bad() -> @Future<i32> {
    return 0;
}

----- ERROR
error: `#[@result]` requires a `-> @Result<…>` return type
  ┌─ :4:5
  │
4 │     return 0;
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
