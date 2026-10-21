# std_io_process_start_parallel

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> Several `Captured` children run at once and their `wait()`s are awaited together (`async.runAll`): the answers come back in the order of the tasks, each with its own stdout, stderr and status.
