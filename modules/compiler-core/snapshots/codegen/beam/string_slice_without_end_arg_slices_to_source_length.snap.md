----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "hello";
    val tail = s.slice(2);
    @print(tail.len);
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: arity mismatch
  ┌─ :3:18
  │
3 │     val tail = s.slice(2);
  │                  ^

  'slice' expected 2 argument(s), got 1
```

