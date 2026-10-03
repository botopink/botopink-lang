----- SOURCE CODE
val x: string = 42;

----- ERROR
error: type mismatch
  ┌─ main.bp:1:17
  │
1 │ val x: string = 42;
  │                 ^

  expected: string
  found:    i32
