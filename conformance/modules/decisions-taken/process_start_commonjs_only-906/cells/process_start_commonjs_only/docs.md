# process_start_commonjs_only

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> `io.process.start` works on commonJS alone: on erlang, beam and wasm a call to it is refused at the call (`std-unsupported-on-target`, decision 906); importing `io.process` is fine everywhere, and `run` / `spawn` are unchanged. An `env` entry with no `=` or an empty name answers `Error(Other(message))` naming it.
