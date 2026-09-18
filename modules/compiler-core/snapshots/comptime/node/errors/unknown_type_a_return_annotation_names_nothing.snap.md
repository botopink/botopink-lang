----- SOURCE CODE
behavior Maker { fn make() -> NoSuchType; }

----- ERROR
error: unknown type
  ┌─ :1:31
  │
1 │ behavior Maker { fn make() -> NoSuchType; }
  │                               ^

  the type 'NoSuchType' is not defined in this scope
