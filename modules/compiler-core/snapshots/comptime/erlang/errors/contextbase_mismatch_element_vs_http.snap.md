----- SOURCE CODE
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn connection() -> @Context<Http, i32> {
    0;
}
fn bad() -> @Context<Element, i32> {
    val c = use connection();
    state(0);
}

----- ERROR
error: ContextBase mismatch
  ┌─ :8:13
  │
8 │     val c = use connection();
  │             ^

  function returns @Context<Element, _>
  but the `use` expression returns @Context<Http, _>
