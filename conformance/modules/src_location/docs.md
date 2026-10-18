# src_location

The reference text this cell shows (from `conformance/docs.md`, § `comptime compiler.src` and `SourceLocation`):

> `compiler.src` is the place it is written (decision 606 (2): `src` is a member of `compiler`,
> written under `comptime` in a body that runs when the program runs, with `import {compiler}
> from "std"`), evaluated at compile time: the four fields are literals at the call site and the
> expression costs nothing at run time — every backend emits the same code it emits for the
> constructor call `SourceLocation(file: "…", line: N, column: C, fnName: "…")`.
>
> | Field | Value |
> |---|---|
> | `file` | the source file relative to the root of its package, forward slashes, with extension (`src/emilia.bp`, `test/color_test.bp`) |
> | `line`, `column` | the 1-based position of `compiler` — the numbers a diagnostic prints |
> | `fnName` | the enclosing `fn`'s name; `Type.method` inside a method; the test name inside `test "…" { }` (`test_<idx>` for an anonymous block); `""` at module level. A lambda does not change it |
>
> `compiler.src` is read, not called (`compiler.src()` is refused as a member that is read). It
> is a value like any other: `comptime compiler.src.line` reads a field in place. Its consumer
> is the test contract — `std/testing/asserts` messages and the `snap` library's paths are
> computed from the caller's `comptime compiler.src`.
