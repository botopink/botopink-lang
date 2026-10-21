----- SOURCE CODE
val Element = type() implement Renderable
component fn state(initial: i32) -> Component<i32> {
    return initial;
}
fn Counter() -> Element {
    val n = use state(0);
    Element();
}

----- ERROR
error: use-without-component: `use` needs a body marked `component`
  ┌─ main.bp:6:13
  │
6 │     val n = use state(0);
  │             ^

  fn 'Counter' returns 'Element' and carries no `component` marker,
  and only a `component fn` body activates a hook: write `component fn` (decisions 553, 573)
