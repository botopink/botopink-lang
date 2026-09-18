----- SOURCE CODE
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}
test "bad call" {
    val r = add("x", 3);
}

----- ERROR
error: type mismatch
  ┌─ :5:17
  │
5 │     val r = add("x", 3);
  │                 ^

  expected: i32
  found:    string
