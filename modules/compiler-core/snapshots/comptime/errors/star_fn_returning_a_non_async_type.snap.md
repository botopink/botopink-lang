----- SOURCE CODE
#[@future]
fn bad() -> string {
    return "x";
}

----- ERROR
error: effect-wrapper-mismatch: `#[@future]` requires a `-> @Future<…>` return type
  ┌─ :3:5
  │
3 │     return "x";
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
