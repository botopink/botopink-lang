----- SOURCE CODE
fn main() {
    val assert 42 = answer catch 0;
    @print("unreachable");
}

----- ERROR
error: unbound variable
  ┌─ main.bp:2:21
  │
2 │     val assert 42 = answer catch 0;
  │                     ^

  'answer' is not in scope
