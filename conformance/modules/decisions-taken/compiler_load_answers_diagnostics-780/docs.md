# Decision 780 — `compiler.load(path)` compiles a file of the package at build and answers its refusals as data; there is no `compiler.snapshot`.

`compiler.load(path)` compiles another file of the package at build and answers that file's refusals as data, a
`Diagnostic[]`. Each `Diagnostic` has a `code`, a `message`, a `file`, a `line`, a `column` and a `label`, with the same
text and location `botopink build` prints. The path follows `compiler.embed`'s rules: it is relative to the package
root and the file is a build input. The file is compiled as the entry of a package of its own, for the build's
target, and never joins the caller's module graph. Its refusals are only the answer: they are never printed and never
refuse the caller. A file that compiles answers `[]`. There is no `compiler.snapshot`, so comparing an answer stays
`botopink cell check`'s job.

In the example `main` loads two files under `src/cases/`, and no module declares either of them.
[draft/cases/broken.bp](draft/cases/broken.bp) assigns a string to an `i32`. Its load answers one diagnostic, and
`main` prints the count and then that diagnostic's code and location. [draft/cases/fine.bp](draft/cases/fine.bp)
compiles, so its load answers an empty array and `main` prints `0`. The program itself builds and runs, even though
one of the files it loads is refused.

Cells that bear on it: none yet (B-158 builds the member).

[draft/main.bp](draft/main.bp)
