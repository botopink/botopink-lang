----- SOURCE CODE
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Use<Element, i32> {
    initial;
}
#[@use]
fn Counter() -> @Component<Element> {
    val #(count, setCount) = use state(0);
    Element();
}

----- ERROR
error: use-tuple-arity: `val #(…)` from a `use` binds the tuple's elements
  ┌─ :8:5
  │
8 │     val #(count, setCount) = use state(0);
  │     ^

  the pattern binds 2 name(s), but the hook's Return type is not a tuple
