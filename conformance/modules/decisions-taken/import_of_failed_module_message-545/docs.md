# Decision 545 — The wording of `import-of-failed-module` (144)

The example is a chain of three modules. [draft/geometry.bp](draft/geometry.bp) holds the real error: `side` binds a `string` to an `i32`. That module is refused with its own type mismatch, at the line where the mismatch is.

[draft/shapes.bp](draft/shapes.bp) imports `geometry.side`, so it gets one error, at that import item: `` `side` comes from `geometry`, which failed to check — its own errors are reported there (src/geometry.bp) ``. `main.bp` imports the namespace `shapes`, which now failed in turn, so it also gets one error at its import item, written with the same text for a namespace as for a name: `` `shapes` comes from `shapes`, which failed to check — its own errors are reported there (src/shapes.bp) ``.

Each line is true where it stands and names only its direct import, so a reader follows the chain one step at a time down to `geometry.bp`. The uses of `shapes.area` and `side` below the imports get no `unbound variable` of their own. Nothing prints.

Cells in this repository that bear on it: `modules/import_of_failed_module`, `modules/lexer_error_in_imported_module`.

[draft/main.bp](draft/main.bp)
