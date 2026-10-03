----- SOURCE CODE -- main.bp
```botopink
fn f(p: { x: i32 }) -> i32 {
    return 1;
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (removedRecordType)
  ┌─ main.bp:1:9
  │
1 │ fn f(p: { x: i32 }) -> i32 {

  unexpected `{`
```

