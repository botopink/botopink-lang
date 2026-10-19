# Decision 243 — 166 reaches every delimited list — generics, parameters, patterns, imports, types, arrays, record fields, enum bodies, c

The example writes each kind of delimited list in both shapes, and `botopink format` keeps each as written, because the trailing comma alone decides the shape. A list with a comma after its last element prints one element per line and keeps the comma: `Palette`'s enum body, `Point`'s record fields, `describe`'s parameters, the `labels` array and the call `describe(…)` in `main`. A list without that comma prints on one line, whatever its width: the generic `<K, V>`, `Pair`'s fields, the tuple `#(1, labels[0]!)`, the import braces, the pattern `#(n, word)` and the other calls. No width rule opens a list. A one-step pipeline has no comma, so it stays horizontal.

The program prints `red 1:one 3 4`.

Cells in this repository that bear on it: `modules/decisions-taken/bare_variant_expression_refused-587/cases/format_annotation_trailing_comma`.

[draft/main.bp](draft/main.bp)
