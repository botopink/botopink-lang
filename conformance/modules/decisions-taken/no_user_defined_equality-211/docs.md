# Decision 211 — A type cannot define its own equality: `==` is always field by field (210); a method named `equals` has no special role

`Address` declares a method `equals` that always answers `true`, and a method `sameAddress` that ignores the note.
`==` takes no notice of either. It compares the three fields in order: `home == again` is `true`, while `home == side`
is `false` because the notes differ, and `!=` is its negation. `home.equals(far)` answers `true` only because it is an
ordinary call of the method as written, and `home == far` stays `false`. The looser sameness is asked for by its own
name: `home.sameAddress(side)` is `true`. Inside a list the same structural `==` applies element by element, so the
last line is `true`. The program has no `===` and no `behavior Eq`, and no user code runs during a comparison on any
target.

Cells in this repository that also bear on it: `modules/decisions-taken/equality_rule_by_value-348/cases/equality_rule_by_value`,
`modules/decisions-taken/equality_is_structural-210/cases/record_structural_equality`.

[draft/main.bp](draft/main.bp)
