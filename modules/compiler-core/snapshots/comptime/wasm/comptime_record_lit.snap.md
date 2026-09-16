----- SOURCE CODE -- main.bp
```botopink
record RecordField { name: string, typeName: string }
val f = comptime RecordField(name: "x", typeName: "i32");
```

----- COMPILE DIAGNOSTIC -- main
```text
error comptime: expression cannot be evaluated at compile time
 ┌─ :2:18
  │
2 │ val f = comptime RecordField(name: "x", typeName: "i32");
  │                  ^^^^

  'call' is a runtime identifier
```

