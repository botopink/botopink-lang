----- SOURCE CODE
fn nums() -> @Iterator<@Result<i32, string>> {
    yield 1;
    break "not an i32";
}

----- ERROR
error: type mismatch
  ┌─ main.bp:3:5
  │
3 │     break "not an i32";
  │     ^

  expected: i32
  found:    string
