# compiler_load_answers_diagnostics

The reference text this cell shows (from `conformance/docs.md`, § `compiler.load`):

> `comptime compiler.load(path)` compiles a file of the package at build, as the entry of a
> package of its own — the caller's manifest, the `mod` tree beside the file, the build's target
> (decision 780) — and answers `Result<compiler.Module, compiler.Refused>` (decisions 782, 786):
> `Ok(m)` when it compiles, `Error(r)` when it is refused, `r.module` the same `Module` and
> `r.diagnostics` its refusals in the order `botopink build` prints them, never empty. A
> `Diagnostic` is the refusal as printed: `message` the text after `error: `, `file`, `line` and
> `column` where it points, `label` the text beside the caret.
