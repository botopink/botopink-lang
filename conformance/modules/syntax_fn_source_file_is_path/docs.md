# syntax_fn_source_file_is_path

The reference text this cell shows (from `conformance/docs.md`, § Functions expanded at their call):

> `compiler.source(value)` the call's `Source(file, line, col)`; its `file` is the file relative to the package root, as diagnostics print it — `src/main.bp` — never the module path (756).

`where` writes the call's file and line into the run-time call it answers: `src/main.bp:20`, the line of `where(1 + 2)`.
