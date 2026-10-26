# Decision 286 — Both annotation forms are valid and printed as written:

Two annotations can be written as two blocks or as one list, and both mean the same: each item is its own annotation,
run in the order written. `Blocks` writes `#[mark("first")]` and `#[mark("second")]` with a comment between them,
`Listed` writes `#[mark("first"), mark("second")]` on one line, and `Open` the same list with a trailing comma, so one
item per line. `mark`, in [draft/comptime/marks.bp](draft/comptime/marks.bp), appends a `Mark` meta, and each of the
three types reads `first second`. `botopink format` leaves all three as written — it neither joins the blocks nor splits
the list, the comment stays between the blocks, and inside a list the trailing comma alone decides its shape.

Cells that also bear on it: `modules/decisions-taken/bare_variant_expression_refused-587/cases/format_annotation_trailing_comma`.

[draft/main.bp](draft/main.bp)
