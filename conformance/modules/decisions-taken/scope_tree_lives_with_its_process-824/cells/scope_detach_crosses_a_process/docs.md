# scope_detach_crosses_a_process

Decision 824 (3): `scope.detach()` answers a new root over the cell's contexts, with no tree; a task
run by `async.runAll` — a process of its own on erlang and beam — runs a component over it on every
target, and its maker closes it. The erlang and beam store itself is
[`scope_tree_lives_with_its_process`](../scope_tree_lives_with_its_process/docs.md).

[src/main.bp](src/main.bp)
