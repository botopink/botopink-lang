----- SOURCE CODE
#[@use]
fn bad() -> string {
    return "x";
}

----- ERROR
error: effect-wrapper-mismatch: `#[@use]` requires a `-> @Component<C, T>` return type
  ┌─ :3:5
  │
3 │     return "x";
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
