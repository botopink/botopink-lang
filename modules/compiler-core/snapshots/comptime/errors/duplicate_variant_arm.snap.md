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
        Red -> "again";
        Blue -> "blue";
    };
};

----- ERROR
error: unreachable case arm
  ┌─ main.bp:10:16
  │
10 │         Red -> "again";
  │                ^

  variant 'Red' is already covered by an earlier arm ('Color')
