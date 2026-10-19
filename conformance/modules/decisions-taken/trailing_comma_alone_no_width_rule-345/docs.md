# Decision 345 — The trailing comma alone decides a delimited list's shape — 166 as written.

The example is the formatter's output. `Point`'s fields and the `names` array were written with a comma after the last element, so each prints one element per line and keeps the comma. The `long` array has no such comma and stays on one line, past any width. The `describe(…)` call was written open over several lines without that comma and is joined onto one line. Inside `Line(…)` the inner `Point(…)` keeps its open shape for the same reason, while the outer call stays on one line. The `+` run in `describe` is not a delimited list and is broken by width. The program prints `3`, `3`, `point 3,6` and `5`.

Cells in this repository that also bear on it: `modules/format_annotation_trailing_comma`.

[draft/main.bp](draft/main.bp)
