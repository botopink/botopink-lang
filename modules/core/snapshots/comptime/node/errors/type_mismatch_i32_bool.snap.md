----- SOURCE CODE
val bad = 1 + true;

----- ERROR
error: type mismatch
  ┌─ :1:13
  │
1 │ val bad = 1 + true;
  │             ^

  expected: i32
  found:    bool
