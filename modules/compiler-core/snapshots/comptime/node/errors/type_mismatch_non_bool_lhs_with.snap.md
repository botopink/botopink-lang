----- SOURCE CODE
val bad = 1 && true;

----- ERROR
error: type mismatch
  ┌─ :1:11
  │
1 │ val bad = 1 && true;
  │           ^

  expected: bool
  found:    i32
