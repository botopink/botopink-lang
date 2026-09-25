----- SOURCE CODE -- main.bp
```botopink
val greeting = "hi";
val msg = comptime {
    break greeting;
};
fn main() {
    @print(msg);
}
```

----- ERROR
error comptime: expression cannot be evaluated at compile time
 ┌─ :3:11
  │
3 │     break greeting;
  │           ^^^^^^^^

  'greeting' is a runtime identifier
