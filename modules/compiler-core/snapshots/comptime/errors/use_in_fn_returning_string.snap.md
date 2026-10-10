----- SOURCE CODE
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn bad() -> string {
    val x = use state(0);
    "hi";
}

----- ERROR
error: use-without-context-effect: `use` needs a `-> @Component<R>` return on the enclosing fn
  ┌─ main.bp:6:13
  │
6 │     val x = use state(0);
  │             ^

  fn 'bad' returns 'string',
  but only a `-> @Component<R>` body activates a hook (decisions 104, 118)
