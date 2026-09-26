----- SOURCE CODE
val bad = "a" * "b";

----- ERROR
error: `*` takes numbers, not `string`
  ┌─ main.bp:1:11
  │
1 │ val bad = "a" * "b";
  │           ^

  hint: Arithmetic is defined on the integer and float types. `+` also concatenates strings; the other operators do not.
