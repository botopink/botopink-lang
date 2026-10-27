# wasm_foreign_type_prints

Values of a record, a variant and a `Display` type built in `shapes` are printed, compared with `==`, tested with `is` and displayed in `main` — alone, inside an array, a tuple and `unknown` — with the same answers on every target. On wasm each module is a unit of its own: a declared type carries its `$__tinfo`, which every unit's printer and equality reach through the core (decision 1055 (2), (3)).
