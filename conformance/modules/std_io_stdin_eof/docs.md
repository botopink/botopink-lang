# std_io_stdin_eof

The reference text this cell shows (from `conformance/docs.md`, § The command line, `io.stdin`, `io.terminal` and `io.process`):

> `io.stdin.readLine()` is a `Task<?string>`: the next line without its `\n` or `\r\n`, a last line with no
> terminator included, `null` at the end of input — again and again once it has ended. `isTTY()` is `false`
> for a pipe, a file or `/dev/null`; `readChunk()` is the byte-level read, whatever has arrived, `null` at the end.
