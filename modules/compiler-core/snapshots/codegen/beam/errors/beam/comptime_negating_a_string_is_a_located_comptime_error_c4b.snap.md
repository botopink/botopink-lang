----- SOURCE CODE -- main.bp
```botopink
val q = comptime -"s";
```

----- ERROR
error comptime: expression cannot be evaluated at compile time
 ┌─ main.bp:1:18
  │
1 │ val q = comptime -"s";
  │                  ^

  only a number can be negated
