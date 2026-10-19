# std_io_process_forward_signals

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> `Child.forwardSignals()` carries the parent's `Term`, `Hup` and `Winch` (and `Int` where the target can catch it)
> to the child: the parent no longer ends on them, and ends when the child does.
