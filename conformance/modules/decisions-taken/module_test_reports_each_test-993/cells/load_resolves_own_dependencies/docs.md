# load_resolves_own_dependencies

Decision 993 (1): a loaded package resolves its own `dependencies` from its own directory — a `path` dependency the caller does not have resolves, and its `run()` prints through it; a loaded workspace member writing no `"targets"` inherits its workspace's (decision 75).

[src/main.bp](src/main.bp)
