# src_location

The reference text this cell shows (from `conformance/docs.md`, § `comptime compiler.src()` and `SourceLocation`):

> `compiler.src()` is the place it is written (decision 718: `src` is a function of `Compiler`,
> `fn src(self: Self) -> SourceLocation`, always written with its parentheses; decision 606 (2):
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
> `compiler.src` without its parentheses is refused as a member that is a call. The answer is a
> value like any other: `comptime compiler.src().line` reads a field in place. A function that
> runs when the program runs and needs its caller's place takes it as an ordinary parameter,
> `at: SourceLocation`, and the caller writes the argument, `comptime compiler.src()`; a default
> `at: SourceLocation = comptime compiler.src()` would name the module the default is written in
> (decision 671), so none is made. Its consumer is the test contract — `std/testing/asserts`
> messages and the `snap` library's paths are computed from the caller's `comptime compiler.src()`.
