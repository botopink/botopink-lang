# std_io_terminal_not_a_tty

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> `stdoutIsTTY()` and `size()` (`#(columns, rows)`, `null` with no terminal) say what the output is; `setRaw(on)`
> answers `Result<void, TerminalError>` (`NotATerminal` when standard input is none) and `keys()` is the
> `AsyncIter<Key>` of key presses that `parseKey(sequence)` decodes. With no terminal the non-terminal answers are the
> same on every target.
