----- SOURCE CODE
fn main() {
    val b = @is(1);
}

----- ERROR
error: unknown-builtin: unknown builtin `@is` — `is` is an operator
  ┌─ main.bp:2:13
  │
2 │     val b = @is(1);
  │             ^

  hint: Test a type with the operator: `x is T`.
