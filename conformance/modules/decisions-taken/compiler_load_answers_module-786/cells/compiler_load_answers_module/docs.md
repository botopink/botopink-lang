# compiler_load_answers_module

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> The `Module` (decision 786) is the loaded file's, on both sides: `name()` the directory it sits in,
> `path()` the file relative to the package (as a `Diagnostic`'s `file`). It carries no target
> (decision 805 (4)) and no dependency list: the loaded package still resolves its own to compile.
> It is an opaque type (decision 811 (4)): its fields are read through `name()` and `path()`.
