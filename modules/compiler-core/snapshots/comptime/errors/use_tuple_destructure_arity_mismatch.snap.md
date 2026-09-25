----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Context<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    #(base, push);
}
#[@context]
fn LikeWidget() -> Element {
    val #(shown) = use optimistic(12, { c, a -> c + a });
    Element();
}

----- ERROR
error: use-tuple-arity: `val #(…)` from a `use` binds the tuple's elements
  ┌─ :8:5
  │
8 │     val #(shown) = use optimistic(12, { c, a -> c + a });
  │     ^

  the pattern binds 1 name(s), the hook yields a tuple of 2
