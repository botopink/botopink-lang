----- SOURCE CODE
#[@use]
fn bad() -> string {
    return "x";
}

----- ERROR
error: effect-wrapper-mismatch: `#[@use]` requires `-> @Component<…>` or `-> @Use<…>` return type
  ┌─ :3:5
  │
3 │     return "x";
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
