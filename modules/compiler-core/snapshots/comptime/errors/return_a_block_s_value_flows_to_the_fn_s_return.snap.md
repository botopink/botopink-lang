----- SOURCE CODE
fn f() -> i32 {
    val s = { "x" };
    return s;
}

----- ERROR
error: type mismatch
  ┌─ main.bp:3:12
  │
3 │     return s;
  │            ^

  expected: i32
  found:    string
