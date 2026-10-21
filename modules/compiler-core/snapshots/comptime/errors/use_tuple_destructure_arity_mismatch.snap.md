----- SOURCE CODE
val Element = type() implement Renderable
component fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> Component<#(i32, fn(action: i32) -> i32)> {
    val push: fn(i32) -> i32 = { action -> f(base, action) };
    return #(base, push);
}
component fn LikeWidget() -> Component<Element> {
    val #(shown) = use optimistic(12, { c, a -> c + a });
    return Element();
}

----- ERROR
error: use-tuple-arity: `val #(…)` from a `use` binds the tuple's elements
  ┌─ main.bp:7:5
  │
7 │     val #(shown) = use optimistic(12, { c, a -> c + a });
  │     ^

  the pattern binds 1 name(s), the hook yields a tuple of 2
