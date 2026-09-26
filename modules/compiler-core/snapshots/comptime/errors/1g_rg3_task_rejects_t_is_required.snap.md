----- SOURCE CODE
fn empty() -> @Task<> { return 0; }

----- ERROR
error: generic-required-arg-missing: a required generic argument is missing
  ┌─ :1:15
  │
1 │ fn empty() -> @Task<> { return 0; }
  │               ^

  hint: Provide every leading (non-defaulted) type argument; only the trailing defaulted range may be omitted.
