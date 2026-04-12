----- SOURCE CODE
val bad = 3.14 * "oops";

----- ERROR
error: type mismatch
  ┌─ :1:16
  │
1 │ val bad = 3.14 * "oops";
  │                ^

  expected: f64
  found:    string
