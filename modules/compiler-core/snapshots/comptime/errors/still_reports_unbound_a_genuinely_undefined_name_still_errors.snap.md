----- SOURCE CODE
fn a() -> i32 { return nonexistent(); }

----- ERROR
error: unbound variable
  ┌─ main.bp:1:24
  │
1 │ fn a() -> i32 { return nonexistent(); }
  │                        ^

  'nonexistent' is not in scope
