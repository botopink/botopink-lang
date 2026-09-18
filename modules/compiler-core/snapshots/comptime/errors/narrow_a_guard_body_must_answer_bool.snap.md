----- SOURCE CODE
fn isPositive(n: i32) -> n is i32 {
    return n;
}

----- ERROR
error: type mismatch
  ┌─ :2:12
  │
2 │     return n;
  │            ^

  expected: bool
  found:    i32
