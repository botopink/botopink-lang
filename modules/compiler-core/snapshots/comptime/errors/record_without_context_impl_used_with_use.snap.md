----- SOURCE CODE
val Plain = type(x: i32)
fn make() -> Plain {
    Plain(x: 0);
}
#[@context]
fn comp() -> @Context<Element, i32> {
    val p = use make();
    0;
}

----- ERROR
error: use-of-non-context-fn: `use` requires @Context
  ┌─ :7:13
  │
7 │     val p = use make();
  │             ^

  `Plain` does not implement @Context — `use` requires @Context<_, _>
