----- SOURCE CODE
fn empty() -> AsyncIter<> { break; }

----- ERROR
error: generic-required-arg-missing: a required generic argument is missing
  ┌─ main.bp:1:15
  │
1 │ fn empty() -> AsyncIter<> { break; }
  │               ^

  hint: Provide every leading (non-defaulted) type argument; only the trailing defaulted range may be omitted.
