# Decision 176 — † `string.parseInt()` of an integer beyond the `i64` range (−2^63 … 2^63 − 1, 319) is `Error` on every target

`parseInt` answers a `Result<i64, string>`, and `parsed` prints which side came back. The two ends of the `i64` range,
`9223372036854775807` and `-9223372036854775808`, are `Ok` and print in full. One step past either end is `Error`,
the message naming the numeral, and so is a thirty-digit numeral. The number is never clamped, wrapped or rounded to
an `f64`. The last line keeps the largest value and subtracts one, printing `9223372036854775806`. commonJS, erlang,
beam and wasm print the same six lines.

Cells in this repository that also bear on it: `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/string_parse_int_i64_range`.

[draft/main.bp](draft/main.bp)
