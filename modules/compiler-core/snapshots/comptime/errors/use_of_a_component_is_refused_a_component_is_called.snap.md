----- SOURCE CODE
val Element = type implement @Context<Element> { }
#[@use]
fn Card() -> @Component<Element> {
    return Element();
}
#[@use]
fn Page() -> @Component<Element> {
    val c = use Card();
    return Element();
}

----- ERROR
error: use-of-non-context-fn: `use` takes a hook (`@Use<C, _>`), and this is a `@Component<…>` — a component is called, not `use`d
  ┌─ :8:13
  │
8 │     val c = use Card();
  │             ^

  hint: Call it (`Card()`) where its value is needed; `use` activates hooks only.
