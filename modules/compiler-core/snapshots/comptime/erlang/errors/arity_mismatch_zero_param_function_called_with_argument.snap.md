----- SOURCE CODE
pub fn hello() -> string {
    @todo();
}
val bad = hello(42);

----- ERROR
error: unbound variable
  ┌─ :2:5
  │
2 │     @todo();
  │     ^

  'todo' is not in scope
