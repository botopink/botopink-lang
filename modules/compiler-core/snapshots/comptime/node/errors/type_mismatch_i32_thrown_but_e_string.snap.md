----- SOURCE CODE
#[@result]
fn parse(s: string) -> @Result<i32, string> {
    throw 404;
}

----- ERROR
error: type mismatch
  ┌─ :3:5
  │
3 │     throw 404;
  │     ^

  expected: string
  found:    i32
