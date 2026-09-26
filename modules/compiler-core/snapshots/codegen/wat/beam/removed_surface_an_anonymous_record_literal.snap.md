----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val p = record { x: 1 };
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (removedRecordLiteral)
  ┌─ main.bp:2:13
  │
2 │     val p = record { x: 1 };

  unexpected `record`
```

