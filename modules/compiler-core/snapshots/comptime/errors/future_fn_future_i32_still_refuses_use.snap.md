----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
#[@future]
fn Page() -> @Future<i32> {
    val n = use state(0);
    return 0;
}

----- ERROR
error: use-of-non-context-fn: `use` not allowed
  ┌─ :7:13
  │
7 │     val n = use state(0);
  │             ^

  function returns `@Future<i32>` which does not implement @Context
