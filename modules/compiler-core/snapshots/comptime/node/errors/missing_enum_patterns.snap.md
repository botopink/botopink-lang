----- SOURCE CODE
val Color = enum {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    case c {
        Red -> "red";
    }
};

----- ERROR
error: non-exhaustive case
  ┌─ :7:5
  │
7 │     case c {
  │     ^

  'Color' is missing variant(s): Green, Blue
