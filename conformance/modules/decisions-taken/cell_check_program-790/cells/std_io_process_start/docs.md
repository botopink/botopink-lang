# std_io_process_start

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> `io.process.start(cmd, args, cwd, env)` starts a child with no shell, in `cwd` and with the `NAME=value` entries of `env` added to the parent's environment, and answers `Result<Captured, ProcessError>`; `Captured.wait()` is an `Async<Exit>` holding the status and the child's stdout and stderr apart, and answers the same again; `Captured.kill(s)` is `NoSuchProcess` once the child has ended. commonJS only.
