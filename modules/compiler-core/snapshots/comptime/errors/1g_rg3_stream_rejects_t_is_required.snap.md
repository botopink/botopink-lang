----- SOURCE CODE
fn empty() -> @Stream<> { break; }

----- ERROR
error: generic-required-arg-missing: a required generic argument is missing
  ┌─ :1:15
  │
1 │ fn empty() -> @Stream<> { break; }
  │               ^

  hint: Provide every leading (non-defaulted) type argument; only the trailing defaulted range may be omitted.
