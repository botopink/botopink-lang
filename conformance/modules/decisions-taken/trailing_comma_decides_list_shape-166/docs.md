# Decision 166 — A trailing comma decides: a list written with a comma after its last element prints one element per line and keeps the c

The program is written the way `botopink format` leaves it, and the trailing comma alone decides each list's shape. `palette` was written with a comma after its last color, so it prints one element per line and keeps the comma; the call `swatch(…)` was written the same way, so its two arguments sit on their own lines too — the rule holds for every delimited list, arguments, parameters, fields and imports alike. `notes` was written with no comma after its last element, so it stays on one line however long that line is: no width rule opens a list. Removing the comma after `16` would join the call back onto one line. Run, the program prints `rose, sky, lime`, `rose #e11d48 16` and `3`.

Cells in this repository that also bear on it: `modules/decisions-taken/bare_variant_expression_refused-587/cases/format_annotation_trailing_comma`.

[draft/main.bp](draft/main.bp)
