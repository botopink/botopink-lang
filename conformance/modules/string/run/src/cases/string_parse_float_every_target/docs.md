# string_parse_float_every_target

`s.parseFloat()` answers `Result<f64, string>` — a sign, digits, an optional `.` with digits on both sides, an optional exponent; `.5`, `1.`, `NaN`, `Infinity` are an `Error`, an overflow too; the nearest `f64`. `parseInt` and `parseFloat` answer the same on every target, the wasm one included.
