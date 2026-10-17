----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (removedKeywordRecord)
  ┌─ main.bp:1:1
  │
1 │ record Point { x: i32, y: i32 }

  unexpected `record`
```

