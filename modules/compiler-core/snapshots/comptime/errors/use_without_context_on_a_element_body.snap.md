----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn Counter() -> Element {
    val n = use state(0);
    Element();
}

----- ERROR
error: use-without-context-effect: `use` needs `#[@context]` on the enclosing fn
  ┌─ :6:13
  │
6 │     val n = use state(0);
  │             ^

  fn 'Counter' returns 'Element', which implements @Context,
  but only a `#[@context]` body activates a hook (decision 88)
