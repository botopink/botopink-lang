----- SOURCE CODE
val bad = -"s";

----- ERROR
error: `-` takes numbers, not `string`
  ┌─ :1:12
  │
1 │ val bad = -"s";
  │            ^

  hint: Arithmetic is defined on the integer and float types. `+` also concatenates strings; the other operators do not.
