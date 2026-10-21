----- SOURCE CODE
val Element = type()
component fn state(initial: i32) -> Component<i32> {
    return initial;
}
fn bad() -> string {
    val x = use state(0);
    "hi";
}

----- ERROR
error: use-without-component: `use` needs a body marked `component`
  ┌─ main.bp:6:13
  │
6 │     val x = use state(0);
  │             ^

  fn 'bad' returns 'string' and carries no `component` marker,
  and only a `component fn` body activates a hook: write `component fn` (decisions 553, 573)
