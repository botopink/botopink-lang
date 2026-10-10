----- SOURCE CODE
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn Counter() -> Element {
    val n = use state(0);
    Element();
}

----- ERROR
error: use-without-context-effect: `use` needs a `-> @Component<R>` return on the enclosing fn
  ┌─ main.bp:6:13
  │
6 │     val n = use state(0);
  │             ^

  fn 'Counter' returns 'Element',
  but only a `-> @Component<R>` body activates a hook (decisions 104, 118)
