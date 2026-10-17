# std_io_signal_handlers

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> `io.process.onSignal(s, handler)` runs `handler` each time the process receives `s` (`Int`, `Term`, `Hup`, `Winch`);
> several handlers for one signal run in the order they were added, and while one is installed the signal no longer
> ends the process. It answers `@Result<void, ProcessError>`.
