----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
fn connection() -> @Context<Http, i32> {
    0;
}
#[@future]
fn Page() -> @Future<Element> {
    val c = use connection();
    return Element();
}

----- ERROR
error: context-anchor-violation: ContextBase mismatch
  ┌─ :7:13
  │
7 │     val c = use connection();
  │             ^

  function returns @Context<Element, _>
  but the `use` expression returns @Context<Http, _>
