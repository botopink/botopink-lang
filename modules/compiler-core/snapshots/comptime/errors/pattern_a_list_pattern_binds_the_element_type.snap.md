----- SOURCE CODE
fn f(s: string) -> string { return s; }
fn g(xs: i32[]) -> string { return case xs { [first, ..rest] -> f(first); _ -> "n"; }; }

----- ERROR
error: type mismatch
  ┌─ main.bp:2:67
  │
2 │ fn g(xs: i32[]) -> string { return case xs { [first, ..rest] -> f(first); _ -> "n"; }; }
  │                                                                   ^

  expected: string
  found:    i32
