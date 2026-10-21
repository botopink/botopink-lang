# root_closed_by_run

Decision 825: `run` with no scope makes its own root and closes it when the component settles, so a
request rendered on the BEAM leaves no `{bp_scope, _}` entry in its process (825 (3)); a root
handed to `run` is left open; a scope used after its root's `close()` fails `scope-closed` on every
target. The count of entries is the process dictionary's on erlang and beam, and `0` on commonJS,
which has none.

[src/main.bp](src/main.bp)
