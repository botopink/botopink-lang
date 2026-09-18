----- SOURCE CODE
val f = fn(x: i32) -> i32 { return "s"; };

----- ERROR
error: type mismatch
  ┌─ :1:36
  │
1 │ val f = fn(x: i32) -> i32 { return "s"; };
  │                                    ^

  expected: i32
  found:    string
