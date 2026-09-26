----- SOURCE CODE
val categorize = fn(s: string) -> string {
    return case s {
        "hello" -> "greeting";
    };
};

----- ERROR
error: non-exhaustive case
  ┌─ :2:12
  │
2 │     return case s {
  │            ^

  `string` has no wildcard `_` arm; it cannot be matched exhaustively
