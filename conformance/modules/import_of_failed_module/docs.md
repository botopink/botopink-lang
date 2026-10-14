# import_of_failed_module

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> **An import of a module that failed to check names that module.** A module the
> build refuses — a syntax error, a type error — exports nothing, and the error to
> fix is its own. An importer that uses a name it takes from it is refused once,
> at the import item, naming the module and its file (`import-of-failed-module`:
> `` `area` comes from `shapes`, which failed to check — its own errors are reported
> there (src/shapes.bp) ``), never as an `unbound variable` at the use; the importer's importers name the importer the
> same way, so every line of the report leads to the one real error. A name the
> named module does not declare, where that module checked, is still refused as
> missing.
