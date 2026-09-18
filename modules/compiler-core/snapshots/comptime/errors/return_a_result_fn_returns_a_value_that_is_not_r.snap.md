----- SOURCE CODE
type Oops(msg: string)
#[@result]
fn f() -> @Result<i32, Oops> { return "s"; }

----- ERROR
error: type mismatch
  ┌─ :3:39
  │
3 │ fn f() -> @Result<i32, Oops> { return "s"; }
  │                                       ^

  expected: i32
  found:    string
