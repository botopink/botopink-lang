----- SOURCE CODE
fn run() -> i32 {
    throw "x";
}

----- ERROR
error: throw outside @Result
  ┌─ :2:5
  │
2 │     throw "x";
  │     ^

  'throw' requires the enclosing fn to return '@Result<D, E>'
