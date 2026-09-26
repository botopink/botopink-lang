----- SOURCE CODE
val Element = type() implement @Context<Element>
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn Counter() -> Element {
    val n = use state(0);
    Element();
}

----- ERROR
error: use-without-context-effect: `use` needs a `-> @Component<C, T>` return on the enclosing fn
  ┌─ :6:13
  │
6 │     val n = use state(0);
  │             ^

  fn 'Counter' returns 'Element',
  but only a `-> @Component<C, T>` body activates a hook (decisions 104, 118)
