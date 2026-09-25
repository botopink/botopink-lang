----- SOURCE CODE
val Element = type implement @Context<Element> { }
val Http = type implement @Context<Http> { }
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn connection() -> @Component<Http, i32> {
    0;
}
fn bad() -> @Component<Element, i32> {
    val c = use connection();
    state(0);
}

----- ERROR
error: context-anchor-violation: ContextBase mismatch
  ┌─ :10:13
  │
10 │     val c = use connection();
  │             ^

  function anchors at `Element`
  but the `use` expression returns @Component<Http, _>
