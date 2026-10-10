----- SOURCE CODE
val bad = 3.14 * "oops";

----- ERROR
error: `*` takes numbers, not `string`
  ┌─ main.bp:1:18
  │
1 │ val bad = 3.14 * "oops";
  │                  ^

  hint: Arithmetic is defined on the integer and float types. `+` also concatenates strings; the other operators do not.
