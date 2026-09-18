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
error: parse error (isVariantBinding)
  ┌─ :2:21
  │
2 │     assert x is Some(n);

  unexpected `(`
```

