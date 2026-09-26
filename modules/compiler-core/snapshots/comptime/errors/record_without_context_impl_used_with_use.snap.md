----- SOURCE CODE
val Element = type() implement @Context<Element>
val Plain = type(x: i32)
fn make() -> Plain {
    return Plain(x: 0);
}
fn comp() -> @Component<Element, i32> {
    val p = use make();
    0;
}

----- ERROR
error: use-of-non-context-fn: `use` takes a hook
  ┌─ :7:13
  │
7 │     val p = use make();
  │             ^

  `Plain` is not a hook — `use` requires a hook @Component<_, _>
