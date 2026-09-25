----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
#[@context]
fn Counter() -> Element {
    val #(count, setCount) = use state(0);
    Element();
}

----- ERROR
error: use-tuple-arity: `val #(…)` from a `use` binds the tuple's elements
  ┌─ :7:5
  │
7 │     val #(count, setCount) = use state(0);
  │     ^

  the pattern binds 2 name(s), but the hook's Return type is not a tuple
