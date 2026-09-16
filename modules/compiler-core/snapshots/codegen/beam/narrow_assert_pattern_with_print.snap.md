----- SOURCE CODE -- main.bp
```botopink
fn process(x: ?i32) -> i32 {
    assert x is Some(n);
    return n + 1;
}
fn main() {
    @print(process(42));
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: parse error (unexpectedToken)
  ┌─ :2:14
  │
2 │     assert x is Some(n);

  unexpected `is`
```

