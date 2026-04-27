----- SOURCE CODE
pub fn add(a: i32, b: i32) -> i32 {
    @todo();
}
val bad = add(1);

----- ERROR
error: unbound variable
  ┌─ :2:5
  │
2 │     @todo();
  │     ^

  'todo' is not in scope
