# Decision 391 — The snapshot engine is a library of its own — `snap`, `botopink/snap` at `repository/snap` (326's rule) — and std provides only the general primitives it is written over.

The program does by hand what the `snap` library does for every test, using only what std provides: `compiler.src()` read at build (`comptime`) gives the location of the call, `path.dirname` and `path.join` build `src/__snapshots__/render/card_with_title.snap` from it, and the text methods lower-case the test's name into its slug. It then prints the three header lines of the `botopink-snap 1` format and the blank line that ends them. Nothing in it imports a snapshot module from std, because std has none: `import {testing.snapshots} from "std";` answers the plain unknown-module error, and a test that asserts a snapshot imports `assertAs` from `"snap"` instead. The path rule, the slugifier, the format and the `.new` flow are that library's; std keeps only the general primitives it is written over.

Cells in this repository that also bear on it: `modules/decisions-taken/no_declaration_files_compiler_value-575/cases/compiler_point_reads`.

[draft/main.bp](draft/main.bp)
