----- SOURCE CODE
async fn empty() -> Async<> { return 0; }

----- ERROR
error: generic-required-arg-missing: a required generic argument is missing
  ┌─ main.bp:1:21
  │
1 │ async fn empty() -> Async<> { return 0; }
  │                     ^

  hint: Provide every leading (non-defaulted) type argument; only the trailing defaulted range may be omitted.
