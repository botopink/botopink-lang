----- SOURCE CODE
val Element = type() implement Renderable
fn Card() -> Component<Element> {
    return Element();
}
fn page() -> Element {
    val c = use Card();
    return c;
}

----- ERROR
error: use-without-component: `use` needs a `-> @Component<R>` return on the enclosing fn
  ┌─ main.bp:6:13
  │
6 │     val c = use Card();
  │             ^

  fn 'page' returns 'Element',
  but only a `component fn` body activates a hook: write `component fn` (decisions 104, 118)
