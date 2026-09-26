----- SOURCE CODE
type Token { Text { Bold, Italic }, Hover(inner: Token[]) }
fn f(t: Token) -> string {
    return case t { Text(Bold) -> "b"; Hover(h) -> "h"; };
}

----- ERROR
error: non-exhaustive case
  ┌─ main.bp:3:12
  │
3 │     return case t { Text(Bold) -> "b"; Hover(h) -> "h"; };
  │            ^

  'Token' is missing variant(s): Text
