# cells_by_place_and_identity

Decision 817: std's `Scope` keeps the tree of cells; a child's cell is found again by its place. A
reused cell's contexts are replaced at each render by its parent's as they stand (817 (5)), only its
hooks' slots kept: `Panel` reads `dark` after `light` and makes its memo once.

[src/main.bp](src/main.bp)
