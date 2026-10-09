----- SOURCE CODE
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn Counter() -> @Component<Element> {
    val #(count, setCount) = use state(0);
    return Element();
}

----- ERROR
error: use-tuple-arity: `val #(…)` from a `use` binds the tuple's elements
  ┌─ main.bp:6:5
  │
6 │     val #(count, setCount) = use state(0);
  │     ^

  the pattern binds 2 name(s), but the hook's Return type is not a tuple
