# Decision 817 — std's `Scope` keeps the tree of cells: a child's cell is found again by its place and its component's identity, written by the compiler — the declaration with its type arguments, a type, a lambda's position, and the value of a `#[key]` parameter or field —; a reused cell takes its parent's contexts anew and keeps only its hooks' state; `{ component -> … }` is 574's factory alone; amends 809 (8), 811 (3), 812 (1), 813 (1), 816 (2), (5), (6).

[cells/cells_by_place_and_identity/src/main.bp](cells/cells_by_place_and_identity/src/main.bp)
