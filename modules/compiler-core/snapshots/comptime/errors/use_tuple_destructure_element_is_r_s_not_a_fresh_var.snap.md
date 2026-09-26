----- SOURCE CODE
val Element = type() implement @Context<Element>
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Component<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    #(base, push);
}
fn LikeWidget() -> @Component<Element, Element> {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push("x");
    Element();
}

----- ERROR
error: type mismatch
  ┌─ main.bp:8:10
  │
8 │     push("x");
  │          ^

  expected: i32
  found:    string
