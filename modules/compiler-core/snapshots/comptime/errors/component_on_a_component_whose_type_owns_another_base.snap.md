----- SOURCE CODE
val Element = type() implement @Context<Element>
val Http = type() implement @Context<Http> { }
fn bad() -> @Component<Http, Element> {
    return Element();
}

----- ERROR
error: effect-wrapper-mismatch: a component's `T` implements `@Context<C>` with the `C` of its `@Component<C, T>` — here `T` anchors at `Element`, not `Http`
  ┌─ main.bp:3:13
  │
3 │ fn bad() -> @Component<Http, Element> {
  │             ^

  hint: Write the base the component's `T` owns: `-> @Component<B, T>` where `T implement @Context<B>`.
