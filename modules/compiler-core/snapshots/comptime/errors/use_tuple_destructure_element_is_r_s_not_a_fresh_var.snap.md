----- SOURCE CODE
val Element = type()
component fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> Component<#(i32, fn(action: i32) -> i32)> {
    val push: fn(i32) -> i32 = { action -> f(base, action) };
    return #(base, push);
}
component fn LikeWidget() -> Component<Element> {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push("x");
    return Element();
}

----- ERROR
error: type mismatch
  ┌─ main.bp:8:10
  │
8 │     push("x");
  │          ^

  expected: i32
  found:    string
