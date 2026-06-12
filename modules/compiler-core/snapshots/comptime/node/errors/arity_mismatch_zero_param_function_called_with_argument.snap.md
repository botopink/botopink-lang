----- SOURCE CODE
pub fn hello() -> string {
    @todo();
}
val bad = hello(42);

----- ERROR
error: arity mismatch
  ┌─ :4:11
  │
4 │ val bad = hello(42);
  │           ^

  'hello' expected 0 argument(s), got 1
