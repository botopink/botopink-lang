# Decision 780 — `compiler.load(path)` compiles a file of the package at build and answers its refusals as data; there is no `compiler.snapshot`.

`compiler.load(path)` compiles another file of the package at build, as the entry of a package of its own — the
caller's manifest, its own `mod` tree beside it, the build's target — and answers that file's refusals as data.
Each `Diagnostic` holds a `code`, a `message`, a `file`, a `line`, a `column` and a `label`: the text and the place
`botopink build` prints for the refusal. The loaded file never joins the caller's program, so its refusals never
refuse the caller. Decision 782 makes the answer a `Result` (`Ok` when the file compiles), read with `try … catch`
(783). There is no `compiler.snapshot`: comparing an answer stays `botopink cell check`'s job.

In the cell `main` loads three packages under `packages/`, none of them a module of the program: a type error, a
parse error whose caret carries a label, and a file whose sibling module `helper.bp` (its `mod` tree) is refused,
which the entry's import then names. Each refusal is printed field by field. The refused cases are the path rules,
`@embed`'s: an absolute path, a `..` segment and a path that names no package are refusals of the program that
loads, at the argument.

[cells/compiler_load_answers_diagnostics/src/main.bp](cells/compiler_load_answers_diagnostics/src/main.bp)
[refused/src/cases/load_path_absolute/mod.bp](refused/src/cases/load_path_absolute/mod.bp)
[refused/src/cases/load_path_outside_package/mod.bp](refused/src/cases/load_path_outside_package/mod.bp)
[refused/src/cases/load_not_a_package/mod.bp](refused/src/cases/load_not_a_package/mod.bp)
