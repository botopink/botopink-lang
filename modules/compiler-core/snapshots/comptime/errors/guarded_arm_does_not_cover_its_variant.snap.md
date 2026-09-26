----- SOURCE CODE
val Color = type {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    return case c {
        Red -> "red";
        Green -> "green";
        Blue if false -> "blue";
    };
};

----- ERROR
error: non-exhaustive case
  ┌─ :7:12
  │
7 │     return case c {
  │            ^

  'Color' is missing variant(s): Blue
