----- SOURCE CODE
type Token { Text { Bold }, Hover(inner: Token[]) }
fn f(t: TokenText) -> string { return "x"; }

----- ERROR
error: the type 'TokenText' is not defined in this scope
  ┌─ main.bp:2:9
  │
2 │ fn f(t: TokenText) -> string { return "x"; }
  │         ^

  hint: a section is named by its path: use `Token.Text`
