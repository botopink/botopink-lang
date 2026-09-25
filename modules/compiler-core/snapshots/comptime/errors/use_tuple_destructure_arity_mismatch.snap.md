----- SOURCE CODE
val Element = type implement @Context<Element> { }
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Component<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    #(base, push);
}
fn LikeWidget() -> @Component<Element, Element> {
    val #(shown) = use optimistic(12, { c, a -> c + a });
    Element();
}

----- ERROR
error: use-tuple-arity: `val #(…)` from a `use` binds the tuple's elements
  ┌─ :7:5
  │
7 │     val #(shown) = use optimistic(12, { c, a -> c + a });
  │     ^

  the pattern binds 1 name(s), the hook yields a tuple of 2
