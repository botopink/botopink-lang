----- SOURCE CODE
val Element = type implement @Context<Element, Element> { }
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Context<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    #(base, push);
}
#[@context]
fn LikeWidget() -> Element {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push("x");
    Element();
}

----- ERROR
error: type mismatch
  ┌─ :9:10
  │
9 │     push("x");
  │          ^

  expected: i32
  found:    string
