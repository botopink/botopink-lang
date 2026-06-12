----- SOURCE CODE
val Color = enum {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    case c {
        Red -> "red";
        Green -> "green";
        Blue if false -> "blue";
    }
};

----- ERROR
error: non-exhaustive case
  ┌─ :7:5
  │
7 │     case c {
  │     ^

  'Color' is missing variant(s): Blue
