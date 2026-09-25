----- SOURCE CODE
type Oops(msg: string)
fn f() -> @Result<i32, Oops> { return "s"; }

----- ERROR
error: type mismatch
  ┌─ :2:39
  │
2 │ fn f() -> @Result<i32, Oops> { return "s"; }
  │                                       ^

  expected: i32
  found:    string
