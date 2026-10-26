# compiler_src_is_a_call

The reference text this cell shows (from `conformance/docs.md`, § `comptime compiler.src()` and `SourceLocation`):

> `compiler.src` without its parentheses is refused as a member that is a call. The answer is a
> value like any other: `comptime compiler.src().line` reads a field in place. A function that
> runs when the program runs and needs its caller's place takes it as an ordinary parameter,
> `at: SourceLocation`, and the caller writes the argument, `comptime compiler.src()`; a default
> `at: SourceLocation = comptime compiler.src()` would name the module the default is written in
> (decision 671), so none is made. Its consumer is the test contract — `std/testing/asserts`
> messages and the `snap` library's paths are computed from the caller's `comptime compiler.src()`.
