# compiler_load_own_target_type

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> The `Module` (decision 786) is the loaded file's, on both sides: `name` the directory it sits in,
> `path` the file relative to the package (as a `Diagnostic`'s `file`). It carries no target
> (decision 805 (4)) and no dependency list: the loaded package still resolves its own to compile.

A module that loads declares its own `Target`; `Target.Erlang` and `Target.Browser` are its variants.
