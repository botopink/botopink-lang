----- SOURCE CODE
val bad = !42;

----- ERROR
error: type mismatch
  ┌─ :1:12
  │
1 │ val bad = !42;
  │            ^

  expected: bool
  found:    i32
