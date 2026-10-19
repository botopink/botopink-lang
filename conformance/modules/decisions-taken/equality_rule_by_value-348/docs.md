# Decision 348 — 210 and 211 are the rule for `==`.

`==` compares by value, recursively, and runs no user code. `a == b` is `true` because the two points hold the same
fields, and `a == c` is `false`. `Point` declares a method named `equals` that answers `true` for anything, and it changes
nothing: `==` never calls it, so it is just a method, and `a.equals(c)` prints `true` only because that is what its body
says. Another notion of sameness is a method with its own name — `sameRow`, which answers `true` for `a` and `c`. The
comparison reaches inside a tuple holding a list of records, and into enum variants and their payloads, so the next two
lines print `true`. The last line is `false`: inside a list too, `f64` under `==` is a total order in which `0.0` and
`-0.0` differ (214).

Cells that also bear on it: `modules/record_structural_equality`, `modules/generic_record_equality_unwritten`,
`modules/f64_equality_total_order`, `modules/comptime_deep_structure_equality`, `modules/type_identity_equality`.

[draft/main.bp](draft/main.bp)
