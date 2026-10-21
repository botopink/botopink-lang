# std_io_process_start_refused_off_node

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> `io.process.start` works on commonJS alone: on erlang and beam it answers `Error(Unsupported)`, on wasm the call is refused at the call (`std-unsupported-on-target`); importing `io.process` is fine everywhere.
