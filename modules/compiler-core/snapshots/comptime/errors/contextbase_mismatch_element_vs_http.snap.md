----- SOURCE CODE
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn connection() -> @Context<Http, i32> {
    0;
}
#[@context]
fn bad() -> @Context<Element, i32> {
    val c = use connection();
    state(0);
}

----- ERROR
error: context-anchor-violation: ContextBase mismatch
  ┌─ :9:13
  │
9 │     val c = use connection();
  │             ^

  function returns @Context<Element, _>
  but the `use` expression returns @Context<Http, _>
