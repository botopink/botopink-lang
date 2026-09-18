----- SOURCE CODE
fn main() {
    val answer = 42;
    val assert 42 = answer catch fallback;
    @print(answer);
}

----- ERROR
error: unbound variable
  ┌─ :3:34
  │
3 │     val assert 42 = answer catch fallback;
  │                                  ^

  'fallback' is not in scope
