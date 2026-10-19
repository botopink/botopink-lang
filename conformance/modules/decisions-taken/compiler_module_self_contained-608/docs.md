# Decision 608 — (a), as 606 and 607 narrowed it: `compiler.bp` is self-contained and the first std module; there is no `reflection.bp`.

The example imports `SourceLocation` and `DeclKind` from std's `compiler` module as it imports `compiler` itself, with no `reflection` module beside it. `here` answers the `SourceLocation` of the place `comptime compiler.src()` is written, and `main` prints its file and function name. The decorator `kindOf` reads the kind of the declaration it annotates into a `DeclKind` value and records whether it is a function in a meta record `Kind`, which `main` reads at build. The program prints `src/main.bp here`, `home is a function: true` and `home`.

Cells in this repository that also bear on it: `modules/src_location` (`SourceLocation` read without the import).

[draft/main.bp](draft/main.bp)
