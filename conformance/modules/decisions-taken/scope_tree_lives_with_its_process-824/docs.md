# Decision 824 — On erlang and beam a root's tree of cells lives in the process dictionary of the process that made the root, under one entry keyed by the root's ref, and ends with that process or at `root.close()`; a scope crosses a process only as `scope.detach()`, a fresh root over its contexts; amends 809 (8), 816 (4), 771's "process dictionary or ETS".

[cells/scope_tree_lives_with_its_process/src/main.bp](cells/scope_tree_lives_with_its_process/src/main.bp)

[cells/scope_detach_crosses_a_process/src/main.bp](cells/scope_detach_crosses_a_process/src/main.bp)
