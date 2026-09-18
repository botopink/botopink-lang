----- SOURCE CODE
fn f(p: NoSuchType) -> i32 { return 1; }

----- ERROR
error: unknown type
  ┌─ :1:9
  │
1 │ fn f(p: NoSuchType) -> i32 { return 1; }
  │         ^

  the type 'NoSuchType' is not defined in this scope
