----- SOURCE CODE
#[@iterator]
fn empty() -> @Iterator<> { break; }

----- ERROR
error: generic-required-arg-missing: a required generic argument is missing

  hint: Provide every leading (non-defaulted) type argument; only the trailing defaulted range may be omitted.
