# Decision 770 — (a): a package with no `"targets"` holds the intersection of its dependencies' targets (and its workspace's, when it is a member); 676 refuses only a package that declares a target a dependency lacks.

A package that writes no `"targets"` holds the targets every one of its declared dependencies holds, narrowed further by its workspace's when it is a member that inherits them, and every target when nothing narrows it. Such a package is never refused for its dependencies' targets: it runs where they run, and a build for a target one of them does not hold is refused `dependency-target-missing` at that dependency's line, so no dependency is compiled for a target it does not hold. A package that writes its `"targets"` is held to them, as decision 676 says: a dependency lacking one of them refuses its manifest on every build. `botopink cell check` runs a cell that writes no `"targets"` on the targets it holds and audits the others.

Cells in this repository that also bear on it: `decisions-taken/dependency_target_missing_refused-676`.

[cases/targets_default_is_dependencies_intersection/src/main.bp](cases/targets_default_is_dependencies_intersection/src/main.bp)
[cases/targets_declared_beyond_dependency/src/main.bp](cases/targets_declared_beyond_dependency/src/main.bp)
