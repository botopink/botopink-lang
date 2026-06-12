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
        Red -> "again";
        Blue -> "blue";
    }
};

----- ERROR
error: unreachable case arm
  ┌─ :10:16
  │
10 │         Red -> "again";
  │                ^

  variant 'Red' is already covered by an earlier arm ('Color')
