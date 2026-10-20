----- SOURCE CODE
val Element = type() implement Renderable
component fn Card() -> Component<Element> {
    return Element();
}
fn page() -> Element {
    val c = use Card();
    return c;
}

----- ERROR
error: use-without-component: `use` needs a body marked `component`
  ┌─ main.bp:6:13
  │
6 │     val c = use Card();
  │             ^

  fn 'page' returns 'Element' and carries no `component` marker,
  and only a `component fn` body activates a hook: write `component fn` (decisions 553, 573)
