----- SOURCE CODE
fn f() -> i32 {
    val s = @block{ return "x"; };
    return s;
}

----- ERROR
error: type mismatch
  ┌─ :3:12
  │
3 │     return s;
  │            ^

  expected: i32
  found:    string
