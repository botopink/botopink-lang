# Decision 455 — `str_slice` and `mem_eq` are deleted from `wat_prelude`: nothing calls them.

The example indexes and slices `"añb😀c"`, where `ñ` takes two bytes and `😀` four in UTF-8. Positions count code points, not bytes, on wasm as on every other target. The length is `5`, `s[1]` is `ñ`, `s[3]` is `😀`, `s[1..4]` is `ñb😀`, and `s[3..5]` is `😀c`.

Cells in this repository that also bear on it: `modules/index_and_slice_sugar`, `modules/string_code_points_every_width`, `modules/string_slice_in_if_branch`.

[draft/main.bp](draft/main.bp)
