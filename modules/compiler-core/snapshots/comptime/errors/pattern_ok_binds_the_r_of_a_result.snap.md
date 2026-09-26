----- SOURCE CODE
type Oops(msg: string)
fn parse(s: string) -> @Result<i32, Oops> { return 1; }
fn f(s: string) -> string { return s; }
fn g() -> string { return case parse("1") { Ok(v) -> f(v); Err(e) -> "e"; }; }

----- ERROR
error: type mismatch
  ┌─ main.bp:4:56
  │
4 │ fn g() -> string { return case parse("1") { Ok(v) -> f(v); Err(e) -> "e"; }; }
  │                                                        ^

  expected: string
  found:    i32
