----- SOURCE CODE
val Element = type implement @Context<Element> { }
val Http = type implement @Context<Http> { }
#[@use]
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
#[@use]
fn connection() -> @Component<Http, i32> {
    initial;
}
#[@use]
fn Mixed() -> @Component<Element, Element> {
    val a = use state(0);
    val b = use connection();
    return Element();
}

----- ERROR
error: context-anchor-violation: two ContextBases in one body
  ┌─ :14:13
  │
14 │     val b = use connection();
  │             ^

  this body's base is `Element`, fixed by the `use` on line 13
  but this `use` returns @Component<Http, _>
