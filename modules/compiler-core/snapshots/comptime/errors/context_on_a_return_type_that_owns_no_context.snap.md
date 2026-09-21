----- SOURCE CODE
#[@context]
fn bad() -> i32 {
    return 0;
}

----- ERROR
error: effect-wrapper-mismatch: `#[@context]` requires a `-> @Context<…>` return type
  ┌─ :3:5
  │
3 │     return 0;
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
