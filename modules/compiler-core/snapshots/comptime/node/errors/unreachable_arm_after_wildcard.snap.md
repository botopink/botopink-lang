----- SOURCE CODE
val Color = enum {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    case c {
        Red -> "red";
        _ -> "other";
        Blue -> "blue";
    }
};

----- ERROR
error: unreachable case arm
  ┌─ :10:17
  │
10 │         Blue -> "blue";
  │                 ^

  this arm is already covered by an earlier arm ('Color')
