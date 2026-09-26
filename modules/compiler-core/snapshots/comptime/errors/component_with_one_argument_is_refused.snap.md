----- SOURCE CODE
val Element = type implement @Context<Element> { }
fn Card() -> @Component<Element> {
    return Element();
}

----- ERROR
error: generic-required-arg-missing: a required generic argument is missing
  ┌─ :2:14
  │
2 │ fn Card() -> @Component<Element> {
  │              ^

  hint: Provide every leading (non-defaulted) type argument; only the trailing defaulted range may be omitted.
