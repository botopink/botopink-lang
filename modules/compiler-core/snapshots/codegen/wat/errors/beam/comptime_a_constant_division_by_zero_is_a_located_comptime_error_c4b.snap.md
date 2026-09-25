----- SOURCE CODE -- main.bp
```botopink
val q = comptime 1 / 0;
```

----- ERROR
error comptime: expression cannot be evaluated at compile time
 ┌─ :1:22
  │
1 │ val q = comptime 1 / 0;
  │                      ^

  division by zero
