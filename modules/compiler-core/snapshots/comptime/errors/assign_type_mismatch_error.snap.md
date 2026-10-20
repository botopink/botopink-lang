----- SOURCE CODE
fn f() -> void {
    var x = 0;
    x = "oops";
}

----- ERROR
error: type mismatch
  ┌─ main.bp:3:5
  │
3 │     x = "oops";
  │     ^

  expected: i32
  found:    string
