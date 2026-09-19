----- SOURCE CODE
fn f(s: string) -> string { return s; }
fn g(x: i32) -> string { return case x { y if (y > 0) -> f(y); _ -> "n"; }; }

----- ERROR
error: type mismatch
  ┌─ :2:60
  │
2 │ fn g(x: i32) -> string { return case x { y if (y > 0) -> f(y); _ -> "n"; }; }
  │                                                            ^

  expected: string
  found:    i32
