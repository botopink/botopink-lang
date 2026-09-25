----- SOURCE CODE
val Element = type implement @Context<Element> { }
#[@use]
fn Card() -> Element {
    return Element();
}

----- ERROR
error: effect-missing-wrapper: `#[@use]` requires `-> @Component<…>` or `-> @Use<…>` return type
  ┌─ :4:5
  │
4 │     return Element();
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
