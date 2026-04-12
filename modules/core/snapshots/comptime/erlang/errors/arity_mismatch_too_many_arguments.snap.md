----- SOURCE CODE
pub fn greet(name: string) -> string {
    return "hi";
}
val bad = greet("a", "extra");

----- ERROR
error: arity mismatch
  ┌─ :4:11
  │
4 │ val bad = greet("a", "extra");
  │           ^

  'greet' expected 1 argument(s), got 2
