----- SOURCE CODE
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn Counter() -> Element {
    val n = use state(0);
    Element();
}

----- ERROR
error: use-without-context-effect: `use` needs `#[@use]` on the enclosing fn
  ┌─ :7:13
  │
7 │     val n = use state(0);
  │             ^

  fn 'Counter' returns 'Element',
  but only a `#[@use]` body activates a hook (decision 104)
