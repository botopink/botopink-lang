# scope_tree_lives_with_its_process

Decision 824: on erlang and beam a root's tree is one entry of the process dictionary of the process
that made it — one root open is one `{bp_scope, _}` entry, gone at `close()` —; a scope crosses a
process only as `scope.detach()`, a fresh root over its contexts; read undetached in another process
it fails `scope-foreign`. `async.runAll` runs each task in a process of its own on erlang and beam;
on commonJS every task shares the one process, so the undetached scope is read there and no entry
is counted (`snapshot/targets/commonJS/`).

[src/main.bp](src/main.bp)
