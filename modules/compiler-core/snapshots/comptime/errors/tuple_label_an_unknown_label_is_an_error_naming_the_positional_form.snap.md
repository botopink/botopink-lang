----- SOURCE CODE
fn loadTyped() -> #(string, i32) {
    return #("SP", 12);
}
val n = loadTyped().name;

----- ERROR
error: this tuple has no element labeled `name`
  ┌─ :4:21
  │
4 │ val n = loadTyped().name;
  │                     ^

  hint: labels come from the tuple's written type or from the variables it was built from; use the position instead: `._0`, `._1`, …
