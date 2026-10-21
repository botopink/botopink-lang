# Decision 240 — wasm counts a string's index in codepoints, as erlang and beam: `length`, `at`, `slice`, `indexOf`, `lastIndexOf` walk U

`s` mixes widths in UTF-8: `€`, `日`, `本` and `→` take three bytes each, `·` two, and `1` and `x` one. On wasm, whose
strings are UTF-8 bytes, each operation walks the sequences, so every number below counts codepoints. `length` is `7`,
not `16`. `at(0)` is `€` and `at(4)` is `本`, whole characters, and `at(-1)` counts from the end to `x`.
`slice(2, 5)` is `·日本`. `indexOf("→")` is `5` and `indexOf("x")` is `6`, and `lastIndexOf("本")` is `4`. An index
`indexOf` answers reads back through `at` as the same character, so the last line is `true`. erlang, beam and commonJS
print the same nine lines, giving one answer for the four targets.

Cells in this repository that also bear on it: `modules/decisions-taken/string_index_counts_codepoints-320/run/src/cases/string_index_of_codepoints`,
`modules/decisions-taken/string_index_counts_codepoints-320/run/src/cases/string_codepoint_slice_and_code`.

[draft/main.bp](draft/main.bp)
