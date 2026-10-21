# Decision 770 — (a): a package with no `"targets"` holds the intersection of its dependencies' targets (and its workspace's, when it is a member); 676 refuses only a package that declares a target a dependency lacks.

The first cell is a program with no `"targets"` of its own: it holds the intersection of its dependencies' targets and runs there, and a build for another target is refused `dependency-target-missing`. The second declares a target a dependency lacks, so 676's refusal still applies at that dependency's line.
[cells/targets_declared_beyond_dependency/src/main.bp](cells/targets_declared_beyond_dependency/src/main.bp)
[cells/targets_default_is_dependencies_intersection/src/main.bp](cells/targets_default_is_dependencies_intersection/src/main.bp)
