----- SOURCE CODE
val bad = true || 0;

----- ERROR
error: type mismatch
  ┌─ :1:19
  │
1 │ val bad = true || 0;
  │                   ^

  expected: bool
  found:    i32
