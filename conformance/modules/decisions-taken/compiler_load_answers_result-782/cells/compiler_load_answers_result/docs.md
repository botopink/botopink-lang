# compiler_load_answers_result

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> `comptime compiler.load(path)` compiles a file of the package at build, as the entry of a
> package of its own — the caller's manifest, the `mod` tree beside the file, the build's target
> (decision 780) — and answers `Result<void, compiler.Diagnostic[]>` (decision 782): `Ok` when it
> compiles, `Error(ds)` when it is refused, `ds` its refusals in the order `botopink build` prints
> them. A `Diagnostic` is the refusal as printed: `message` the text after `error: `, `file`,
> `line` and `column` where it points, `label` the text beside the caret.
