# Decision 689 — On erlang and beam a spawned child runs behind a port: its stdin is a pipe, not the parent's, and its stderr is merged into stdout; kept and documented in `libs/std/AGENTS.md` and the function's doc.

`process.spawn` starts `sh` without waiting, and `wait()` answers its exit status. On erlang and beam the child runs
behind a port, and two things follow, kept as the language's answer and documented with the function: its stdin is a
pipe of the port, not the parent's, so `test -t 0` fails and the child prints `stdin is no terminal`; and its stderr is merged into its stdout, so `to stderr` arrives in the parent's stdout after
`to stdout`. On commonJS the child shares the parent's descriptors: `to stderr` goes to stderr, and its stdin is the parent's, a
terminal or not. Every target then
prints `exit 0`. A port program that hands the parent's descriptors over is a step of its own, taken when a library
needs it.

Cells that also bear on it: `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_process_spawn`, `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_process_forward_signals`.

[draft/main.bp](draft/main.bp)
