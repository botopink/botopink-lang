----- SOURCE CODE
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn bad() -> string {
    val x = use state(0);
    "hi";
}

----- ERROR
error: `use` not allowed
  ┌─ :5:13
  │
5 │     val x = use state(0);
  │             ^

  function returns `string` which does not implement @Context
