----- SOURCE CODE -- main.bp
```botopink
val result = comptime {
    val x = 10;
    break x * 2;
};
```

----- COMPILE DIAGNOSTIC -- main
```text
error comptime: expression cannot be evaluated at compile time
 ┌─ :2:5
  │
2 │     val x = 10;
  │     ^^^^^^^

  'binding' is a runtime identifier
```

