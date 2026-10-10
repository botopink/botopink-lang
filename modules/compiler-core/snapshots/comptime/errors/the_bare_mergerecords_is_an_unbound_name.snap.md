----- SOURCE CODE
type A(x: i32)
type B(y: string)
val Merged = mergeRecords(A, B);

----- ERROR
error: unbound variable
  ┌─ main.bp:3:14
  │
3 │ val Merged = mergeRecords(A, B);
  │              ^

  'mergeRecords' is not in scope
