----- SOURCE CODE
val Element = type() implement @Renderable
fn Card() -> @Component<Element> {
    return Element();
}
fn Page() -> @Component<Element> {
    val c = use Card();
    return Element();
}

----- ERROR
error: use-of-non-context-fn: `use` takes a hook, and this is a component (its `R` implements `@Renderable`) — a component is called, not `use`d
  ┌─ main.bp:6:13
  │
6 │     val c = use Card();
  │             ^

  hint: Call it (`Card()`) where its value is needed; `use` activates hooks only.
