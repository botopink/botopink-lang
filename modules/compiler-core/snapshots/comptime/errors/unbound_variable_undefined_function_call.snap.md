----- SOURCE CODE
val x = undefinedFn(42);

----- ERROR
error: unbound variable
  ┌─ main.bp:1:9
  │
1 │ val x = undefinedFn(42);
  │         ^

  'undefinedFn' is not in scope
