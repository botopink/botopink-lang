----- SOURCE CODE
val Element = type implement @Context<Element> { }
val Http = type implement @Context<Http> { }
#[@use]
fn state(initial: i32) -> @Use<Element, i32> {
    initial;
}
#[@use]
fn connection() -> @Use<Http, i32> {
    0;
}
#[@use]
fn bad() -> @Use<Element, i32> {
    val c = use connection();
    state(0);
}

----- ERROR
error: context-anchor-violation: ContextBase mismatch
  ┌─ :13:13
  │
13 │     val c = use connection();
  │             ^

  function anchors at `Element`
  but the `use` expression returns @Use<Http, _>
