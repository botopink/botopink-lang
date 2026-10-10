----- SOURCE CODE
type Pet { Dog(name: i32), Cat(name: i32) }
fn f(s: string) -> string { return s; }
fn g(p: Pet) -> string { return case p { Dog(b) | Cat(b) -> f(b); }; }

----- ERROR
error: type mismatch
  ┌─ main.bp:3:63
  │
3 │ fn g(p: Pet) -> string { return case p { Dog(b) | Cat(b) -> f(b); }; }
  │                                                               ^

  expected: string
  found:    i32
