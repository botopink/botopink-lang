----- SOURCE CODE
fn add(a: i32, b: i32) -> i32 { return a + b; }
val r = 1 |> add(1, 2);

----- ERROR
error: arity mismatch
  ┌─ main.bp:2:14
  │
2 │ val r = 1 |> add(1, 2);
  │              ^

  'add' expected 2 argument(s), got 3
