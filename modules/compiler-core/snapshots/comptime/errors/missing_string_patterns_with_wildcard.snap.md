----- SOURCE CODE
val categorize = fn(s: string) -> string {
    case s {
        "hello" -> "greeting";
    }
};

----- ERROR
error: non-exhaustive case
  ┌─ :2:5
  │
2 │     case s {
  │     ^

  `string` has no wildcard `_` arm; it cannot be matched exhaustively
