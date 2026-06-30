----- SOURCE CODE
val err = @comptimeError("field x not found");

----- ERROR
error: comptime error: field x not found
  ┌─ :1:26
  │
1 │ val err = @comptimeError("field x not found");
  │                          ^

  hint: This error was raised by @comptimeError during type checking.
