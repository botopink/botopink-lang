----- SOURCE CODE
val Color = type {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    return case c {
        Red -> "red";
        _ -> "other";
        Blue -> "blue";
    };
};

----- ERROR
error: unreachable case arm
  ┌─ main.bp:10:17
  │
10 │         Blue -> "blue";
  │                 ^

  this arm is already covered by an earlier arm ('Color')
