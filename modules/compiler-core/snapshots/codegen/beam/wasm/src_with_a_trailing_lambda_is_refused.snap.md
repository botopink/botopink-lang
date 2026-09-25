----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val loc = @src { 1; };
}
```

----- COMPILE DIAGNOSTIC -- main
```text
error: src-takes-no-arguments: `@src()` takes no arguments
  ┌─ :2:15
  │
2 │     val loc = @src { 1; };
  │               ^

  hint: Write `@src()` — the location is the call site's own; there is nothing to pass.
```

