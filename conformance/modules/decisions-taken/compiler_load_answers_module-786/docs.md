# Decision 786 — `compiler.load` answers `Result<Module, Refused>` — `Module(name, path, target)` on both sides, `Refused(module: Module, diagnostics: Diagnostic[])` —, so a reader takes the loaded file from the data; amends 780, 782 (the `void` answer), 783's handler reads `r.diagnostics`, 784 (1)–(2).

`compiler.load(path)` answers `Result<compiler.Module, compiler.Refused>`. The `Module` is the loaded file's, on
both sides: `name()` the directory it sits in, `path()` the file relative to the package (as a `Diagnostic`'s
`file`) — std's `Module` is opaque, its fields read through those methods (decision 811 (4)). It carries no target
(decision 805 (4)) and no dependency list. A refusal is a `Refused`: the same `Module` and its `diagnostics`, never empty.

In the cell `main` loads a file that compiles and one that does not, reading each answer with `case`: it prints the
`Module`'s `name()` and `path()` on `Ok`, and the refused file's `r.module.path()` and `name()` inside `Refused`.

[cases/compiler_load_answers_module/src/main.bp](cases/compiler_load_answers_module/src/main.bp)
