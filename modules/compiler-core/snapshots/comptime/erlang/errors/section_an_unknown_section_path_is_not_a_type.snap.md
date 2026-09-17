----- SOURCE CODE
type Token { Text { Bold }, Hover(inner: Token[]) }
fn f(t: Token.Nope) -> string { return "x"; }

----- ERROR
error: unknown type

  the type 'Token.Nope' is not defined in this scope
