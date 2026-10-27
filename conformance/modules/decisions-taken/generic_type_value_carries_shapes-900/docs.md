# Decision 900 — On commonJS a value of a generic type carries its type arguments' print shapes: the generic constructor that builds it writes the shapes its call handed it (673) into the value (`__bp_s`), a method that answers a new value of the type copies them, and a generic method reads them where it writes a `K` / `V` as text — so the value prints right wherever it goes, `d.display()` in another module and `print(d)`'s `Display` dispatch included; settles B-115 box 3.

A `Dict<string, f64>` built by std's `Dict.empty()`, `insert` and `Dict.ofEntries` in one module and printed in
another answers the same on every target: `print(d)` and `d.display()` write `Dict("a": 2.0)`, and a dict a method
answers (`insert`, `delete`) keeps writing its floats as floats. On commonJS the value itself carries the print shape of
each type argument, written by the generic constructor from the shapes its call handed it and copied by every method
that answers a new value of the type; `display` reads them off the value, so neither the run-time `Display` dispatch
of `print` nor a call in another module needs to know the static type. erlang, beam and wasm are unchanged.

[cases/generic_type_value_carries_shapes/src/main.bp](cases/generic_type_value_carries_shapes/src/main.bp)
