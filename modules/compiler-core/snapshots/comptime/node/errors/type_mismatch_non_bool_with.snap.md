----- SOURCE CODE
val bad = !42;

----- ERROR
error: type mismatch
  ┌─ :1:11
  │
1 │ val bad = !42;
  │           ^

  expected: i32
  found:    bool
