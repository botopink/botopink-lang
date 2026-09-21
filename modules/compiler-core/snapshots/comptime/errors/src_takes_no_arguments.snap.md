----- SOURCE CODE
fn main() {
    val loc = @src(1);
}

----- ERROR
error: src-takes-no-arguments: `@src()` takes no arguments
  ┌─ :2:15
  │
2 │     val loc = @src(1);
  │               ^

  hint: Write `@src()` — the location is the call site's own; there is nothing to pass.
