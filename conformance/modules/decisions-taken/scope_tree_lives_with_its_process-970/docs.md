# Decision 970 — On erlang and beam a root's tree of cells lives in the process dictionary of the process that made the root, under one entry keyed by the root's ref, and ends with that process or at `root.close()`, which marks the root closed on the four targets; a scope crosses a process only as `scope.detach()`, a seed over its contexts; restates 824 with 825 (2) and 897 (1) folded in, replacing it.

[draft/main.bp](draft/main.bp)
