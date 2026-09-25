----- SOURCE CODE
val Element = type implement @Context<Element> { }
val Http = type implement @Context<Http> { }
#[@use]
fn bad() -> @Component<Http, Element> {
    return Element();
}

----- ERROR
error: effect-wrapper-mismatch: a component's `T` implements `@Context<C>` with the `C` of its `@Component<C, T>` — here `T` anchors elsewhere
  ┌─ :5:5
  │
5 │     return Element();
  │     ^

  hint: The effect annotation and the return wrapper must name the same effect.
