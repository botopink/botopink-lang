----- SOURCE CODE
fn describe(x: i32) -> string {
    val { result } = x;
    return result;
}

----- ERROR
error: not a record type
  ┌─ :2:5
  │
2 │     val { result } = x;
  │     ^

  'i32' is not a record or struct type
