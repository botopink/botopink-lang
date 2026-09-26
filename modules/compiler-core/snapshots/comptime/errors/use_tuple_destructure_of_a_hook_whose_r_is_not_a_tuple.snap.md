----- SOURCE CODE
val Element = type() implement @Context<Element>
fn state(initial: i32) -> @Component<Element, i32> {
    initial;
}
fn Counter() -> @Component<Element, Element> {
    val #(count, setCount) = use state(0);
    Element();
}

----- ERROR
error: use-tuple-arity: `val #(…)` from a `use` binds the tuple's elements
  ┌─ :6:5
  │
6 │     val #(count, setCount) = use state(0);
  │     ^

  the pattern binds 2 name(s), but the hook's Return type is not a tuple
