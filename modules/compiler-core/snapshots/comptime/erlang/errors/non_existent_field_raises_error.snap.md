----- SOURCE CODE
record User { id: i32 }
val NoField = omit(User, "email");

----- ERROR
error: omit: field 'email' not found in type 'User'
  ┌─ :2:26
  │
2 │ val NoField = omit(User, "email");
  │                          ^

  hint: The field name must exist in the record type.
