----- SOURCE CODE -- main.bp
```botopink
val Box = record { weight: i32 }
fn describe(b: ?Box) -> string {
    if (b && b.weight > 10) {
        return "heavy";
    };
    return "light or none";
}
@print(describe(Box(weight: 20)));
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ :3:11
  │
3 │     if (b && b.weight > 10) {

  unexpected `&&`
```

