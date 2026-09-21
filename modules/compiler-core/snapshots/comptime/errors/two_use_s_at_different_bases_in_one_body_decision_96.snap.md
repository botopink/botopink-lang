----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
val Http = type implement @Context<Http, Http> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn connection() -> @Context<Http, i32> {
    initial;
}
#[@context]
fn Mixed() -> Element {
    val a = use state(0);
    val b = use connection();
    return Element();
}

----- ERROR
error: context-anchor-violation: two ContextBases in one body
  ┌─ :12:13
  │
12 │     val b = use connection();
  │             ^

  this body's ContextBase is @Context<Element, _>, fixed by the `use` on line 11
  but this `use` returns @Context<Http, _>
