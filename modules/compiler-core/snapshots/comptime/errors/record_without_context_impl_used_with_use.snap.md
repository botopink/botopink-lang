----- SOURCE CODE
val Element = type() implement @Renderable
val Plain = type(x: i32)
fn make() -> Plain {
    return Plain(x: 0);
}
fn comp() -> @Component<i32> {
    val p = use make();
    return 0;
}

----- ERROR
error: use-of-non-context-fn: `use` takes a hook
  ┌─ main.bp:7:13
  │
7 │     val p = use make();
  │             ^

  `Plain` is not a hook — `use` requires a hook @Component<R>
