# index_keeps_body_count

Decision 891: a list runner (`all`, a render library's children) passes `Place.index(i)`, which keeps
the item half a component body counted: `footer` is made once although its position moves.

[src/main.bp](src/main.bp)
