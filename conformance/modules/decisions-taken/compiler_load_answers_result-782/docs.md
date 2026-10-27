# Decision 782 — `compiler.load(path)` answers a `Result`: `Ok` when the file compiles, `Error` its refusals; it is read with `catch` / `try`, never through `attempt`; amends 780 (1), (2).

`compiler.load(path)` answers `Result<void, compiler.Diagnostic[]>`: `Ok` when the loaded file compiles, `Error(ds)`
when it is refused, `ds` its refusals in the order `botopink build` prints them, never empty. It is read as every
`Result` is — `.isOk()` / `.isError()` ask, `try … catch` handles, `try` propagates — and never through `attempt`,
which contains a crash at run time, not a refusal at build.
Decision 786 amends the answer to `Result<compiler.Module, compiler.Refused>`: `Ok` carries the loaded file's
`Module`, `Error` a `Refused` holding that `Module` and the refusals as `diagnostics`.

In the cell `main` loads a file that compiles and one that does not, asks each answer, and handles both with
`try … catch`: the handler runs for the refused file alone, with at least one refusal.

[cases/compiler_load_answers_result/src/main.bp](cases/compiler_load_answers_result/src/main.bp)
