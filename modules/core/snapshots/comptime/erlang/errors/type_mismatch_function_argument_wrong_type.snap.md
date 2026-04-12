----- SOURCE CODE
pub fn double(x: i32) -> i32 {
    todo;
}
val bad = double("hello");

----- ERROR
error: type mismatch
  ┌─ :4:18
  │
4 │ val bad = double("hello");
  │                  ^

  expected: i32
  found:    string
