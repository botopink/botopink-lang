----- SOURCE CODE
val Element = type() implement @Context<Element>
val Http = type() implement @Context<Http> { }
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn connection() -> @Component<Http, i32> {
    0;
}
fn Mixed() -> @Component<Element, Element> {
    val a = use state(0);
    val b = use connection();
    return Element();
}

----- ERROR
error: context-anchor-violation: two ContextBases in one body
  ┌─ main.bp:11:13
  │
11 │     val b = use connection();
  │             ^

  this body's base is `Element`, fixed by the `use` on line 10
  but this `use` returns @Component<Http, _>
