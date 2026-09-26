----- SOURCE CODE
val bad = !42;

----- ERROR
error: type mismatch
  ┌─ main.bp:1:12
  │
1 │ val bad = !42;
  │            ^

  expected: bool
  found:    i32
