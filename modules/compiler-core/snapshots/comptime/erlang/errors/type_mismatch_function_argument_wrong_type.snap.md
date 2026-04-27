----- SOURCE CODE
pub fn double(x: i32) -> i32 {
    @todo();
}
val bad = double("hello");

----- ERROR
error: unbound variable
  ┌─ :2:5
  │
2 │     @todo();
  │     ^

  'todo' is not in scope
