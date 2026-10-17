----- SOURCE CODE -- main.bp
```botopink
val greeting = "hi";
val msg = comptime { greeting };
fn main() {
    @print(msg);
}
```

----- ERROR
error comptime: expression cannot be evaluated at compile time
 ┌─ main.bp:2:22
  │
2 │ val msg = comptime { greeting };
  │                      ^^^^^^^^

  'greeting' is a runtime identifier
