----- SOURCE CODE -- main.bp
```botopink
val Color = enum {
    Red,
    Green,
    Blue,
};
val name = fn(c: Color) -> string {
    case c {
        Red -> "red";
        Green -> "green";
        Blue -> "blue";
    }
};
```

