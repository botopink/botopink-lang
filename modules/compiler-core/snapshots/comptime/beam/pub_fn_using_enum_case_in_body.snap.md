----- SOURCE CODE -- main.bp
```botopink
val Direction = enum {
    North,
    South,
    East,
    West,
}
pub fn label(d: Direction) -> string {
    val result = case d {
        North -> "N";
        South -> "S";
        East -> "E";
        West -> "W";
        _ -> "?";
    };
    @print(result);
    return result;
}
val n = label(Direction.North);
@print(n);
```

