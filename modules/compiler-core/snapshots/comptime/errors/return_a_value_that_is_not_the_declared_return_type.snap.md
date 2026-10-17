----- SOURCE CODE
fn f() -> i32 { return "s"; }

----- ERROR
error: type mismatch
  ┌─ main.bp:1:24
  │
1 │ fn f() -> i32 { return "s"; }
  │                        ^

  expected: i32
  found:    string
