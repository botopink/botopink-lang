# print_from_io_terminal

The reference text this cell shows (from `conformance/docs.md`, § `print` and `panic`):

> `print(..values: unknown[])` is a function of std's `io/terminal.bp` and `panic(message:
> string = "panic") -> noreturn` one of `failure.bp` (decision 606 (2)): each is imported where it
> is used — `import {io.terminal.print} from "std";`, `import {failure.panic} from "std";`, an
> alias included —, std's own modules by the same import.
