----- SOURCE CODE
val bad = true || 0;

----- ERROR
error: type mismatch
  ┌─ :1:16
  │
1 │ val bad = true || 0;
  │                ^

  expected: i32
  found:    bool
