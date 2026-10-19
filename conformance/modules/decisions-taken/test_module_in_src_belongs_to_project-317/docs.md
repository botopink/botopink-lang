# Decision 317 — `botopink test` in a project whose modules sit in folders: a module whose source is in the project's own `src` belongs t

The package keeps a module in a folder, `src/io/random.bp`, whose first segment is also the name of a std folder. `import {io.random.d6};` — braces, no `from` — reaches the package's own module, while `import {io.terminal} from "std";` reaches std's; the two never mix. `main` makes a `Die` with six sides and prints `6 4 6`. Under `botopink test` the same holds for the module's `test` block: `io/random` is attributed to this project, never to a dependency named `io`, and the type `Die` it declares has its compiled unit written beside `io/random`'s (`<package>@io@random@@Die` on erlang), not at the root of the run.

Cells in this repository that also bear on it: `modules/decisions-taken/own_module_import_without_from-206/cases/import_own_module_with_from`.

[draft/main.bp](draft/main.bp) · [draft/io/random.bp](draft/io/random.bp)
