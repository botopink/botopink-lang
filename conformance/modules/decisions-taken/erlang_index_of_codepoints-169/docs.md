# Decision 169 — Codepoints on erlang: `indexOf` / `lastIndexOf` answer the codepoint index, as `at` / `slice` / `length` do there, so an

`city` holds `ã` and `í`, each one codepoint and two UTF-8 bytes. On erlang, where a string is a UTF-8 binary,
`indexOf(",")` answers `9`, the codepoint index, as `at`, `slice` and `length` count there. It no longer answers the
byte offset `10`. The index goes straight back into the other operations: `city.at(comma)` is `,` and
`city.slice(0, comma)` is `São Paulo`. `lastIndexOf("São")` answers `11`, and slicing from it gives `São Luís`.
Reading back the index of `ã` with `at` gives `ã` itself, never half of its bytes. `lastIndexOf("í")` is `17`, and a
missing substring is `-1`. Every target counts codepoints, so the eight lines are the same on erlang, beam, commonJS
and wasm.

Cells in this repository that also bear on it: `modules/decisions-taken/string_index_counts_codepoints-320/run/src/cases/string_index_of_codepoints`,
`modules/decisions-taken/string_index_counts_codepoints-320/run/src/cases/string_codepoint_slice_and_code`.

[draft/main.bp](draft/main.bp)
