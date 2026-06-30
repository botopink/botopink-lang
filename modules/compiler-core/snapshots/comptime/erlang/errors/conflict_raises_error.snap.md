----- SOURCE CODE
record A { x: i32 }
record B { x: string }
val Merged = mergeRecords(A, B);

----- ERROR
error: mergeRecords: field 'x' has conflicting types in the two records
  ┌─ :3:14
  │
3 │ val Merged = mergeRecords(A, B);
  │              ^

  hint: Fields with the same name must have identical types.
