----- SOURCE CODE
fn parse(s: string) -> @Result<i32, string> {
    throw 404;
}

----- ERROR
error: type mismatch
  ┌─ :2:5
  │
2 │     throw 404;
  │     ^

  expected: string
  found:    i32
