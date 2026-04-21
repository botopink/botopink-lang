----- SOURCE CODE -- main.bp
```botopink
val msg = comptime {
    break greeting;
};
```

----- ERROR
error comptime: expression cannot be evaluated at compile time
 ┌─ :2:11
  │
2 │     break greeting;
  │           ^^^^^^^^

  'greeting' is a runtime identifier
