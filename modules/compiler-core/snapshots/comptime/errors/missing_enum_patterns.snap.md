----- SOURCE CODE
val Color = type {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    return case c {
        Red -> "red";
    };
};

----- ERROR
error: non-exhaustive case
  ┌─ main.bp:7:12
  │
7 │     return case c {
  │            ^

  'Color' is missing variant(s): Green, Blue
