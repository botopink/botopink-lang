----- SOURCE CODE
#[@resultGenerator]
fn nums() -> @ResultGenerator<i32, string> {
    yield 1;
    break "not an i32";
}

----- ERROR
error: type mismatch
  ┌─ :4:5
  │
4 │     break "not an i32";
  │     ^

  expected: string
  found:    i32
