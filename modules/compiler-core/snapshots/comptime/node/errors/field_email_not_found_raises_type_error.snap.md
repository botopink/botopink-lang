----- SOURCE CODE
record User { id: i32, name: string }
val BadPick = pick(User, ["email"]);

----- ERROR
error: pick: field 'email' not found in type 'User'
  ┌─ :2:15
  │
2 │ val BadPick = pick(User, ["email"]);
  │               ^

  hint: All field names must exist in the record type.
