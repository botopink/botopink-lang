----- SOURCE CODE
val Element = type() implement Renderable
fn state(initial: i32) -> Component<i32> {
    return initial;
}
fn bad() -> string {
    val x = use state(0);
    "hi";
}

----- ERROR
error: use-without-component: `use` needs a `-> @Component<R>` return on the enclosing fn
  ┌─ main.bp:6:13
  │
6 │     val x = use state(0);
  │             ^

  fn 'bad' returns 'string',
  but only a `component fn` body activates a hook: write `component fn` (decisions 104, 118)
