----- SOURCE CODE
type Q(lat: bogusType)

----- ERROR
error: unknown type
  ┌─ main.bp:1:13
  │
1 │ type Q(lat: bogusType)
  │             ^

  the type 'bogusType' is not defined in this scope
