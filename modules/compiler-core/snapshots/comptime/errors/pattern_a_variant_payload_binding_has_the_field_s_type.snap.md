----- SOURCE CODE
type E { A(v: i32), B }
fn f(s: string) -> string { return s; }
fn g(e: E) -> string { return case e { A(v) -> f(v); B -> "b"; }; }

----- ERROR
error: type mismatch
  ┌─ main.bp:3:50
  │
3 │ fn g(e: E) -> string { return case e { A(v) -> f(v); B -> "b"; }; }
  │                                                  ^

  expected: string
  found:    i32
