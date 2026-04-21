----- SOURCE CODE
fn f() {
    var x = 0;
    x = "oops";
}

----- ERROR
error: type mismatch
  ┌─ :3:5
  │
3 │     x = "oops";
  │     ^

  expected: i32
  found:    string
