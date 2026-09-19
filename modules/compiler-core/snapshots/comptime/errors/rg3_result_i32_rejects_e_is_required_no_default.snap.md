----- SOURCE CODE
#[@result]
fn parse() -> @Result<i32> { return 0; }

----- ERROR
error: generic-required-arg-missing: a required generic argument is missing

  hint: Provide every leading (non-defaulted) type argument; only the trailing defaulted range may be omitted.
