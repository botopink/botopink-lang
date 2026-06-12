----- SOURCE CODE
#[@future]
fn bad() -> @Result<i32, string> {
    return 0;
}

----- ERROR
error: `#[@future]` requires a `-> @Future<…>` return type
  ┌─ :3:5
  │
3 │     return 0;
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
