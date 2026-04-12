----- SOURCE CODE
pub fn add(a: i32, b: i32) -> i32 {
    todo;
}
val bad = add(1);

----- ERROR
error: arity mismatch
  ┌─ :4:11
  │
4 │ val bad = add(1);
  │           ^

  'add' expected 2 argument(s), got 1
