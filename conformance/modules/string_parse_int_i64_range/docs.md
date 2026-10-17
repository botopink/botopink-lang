# string_parse_int_i64_range

`s.parseInt()` answers `@Result<i64, string>` — an optional `+` / `-` and digits, the whole string; anything else is an `Error` naming the input, and so is an integer past the `i64` range, −2^63 … 2^63 − 1. `parseInt` and `parseFloat` answer the same on every target, the wasm one included.
