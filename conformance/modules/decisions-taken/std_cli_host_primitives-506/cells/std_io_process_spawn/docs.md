# std_io_process_spawn

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> `io.process.spawn(cmd, args)` starts a child with no shell, sharing the parent's streams, and answers
> `Result<Child, ProcessError>` without waiting: `NotFound` and `PermissionDenied` say why nothing started.
> `Child.wait()` is an `Async<i32>` of the exit status (`128 + n` for a child ended by signal `n`) and answers the same
> again; `Child.kill(s)` sends a signal and is `NoSuchProcess` once the child has ended.
