----- SOURCE CODE
type Token { Text { Bold }, Hover(inner: Token[]) }
fn f(t: Token.Nope) -> string { return "x"; }

----- ERROR
error: unknown type
  ┌─ main.bp:2:9
  │
2 │ fn f(t: Token.Nope) -> string { return "x"; }
  │         ^

  the type 'Token.Nope' is not defined in this scope
