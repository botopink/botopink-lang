----- SOURCE CODE
*fn bad() -> string {
    return "x";
}

----- ERROR
error: `#[@future]` requires a `-> @Future<…>` return type
  ┌─ :2:5
  │
2 │     return "x";
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
