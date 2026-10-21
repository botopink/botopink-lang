# scope_tree_lives_with_its_process

Decision 824: on erlang and beam a root's tree is one entry of the process dictionary of the process
that made it — one root open is one `{bp_scope, _}` entry, gone at `close()` —; read undetached in
another process (`async.runAll` runs each task in a process of its own there) it fails
`scope-foreign`. Erlang and beam only: the entry count is a process-dictionary read with no other
target's binding. What crosses a process on every target is
[`scope_detach_crosses_a_process`](../scope_detach_crosses_a_process/docs.md).

[src/main.bp](src/main.bp)
