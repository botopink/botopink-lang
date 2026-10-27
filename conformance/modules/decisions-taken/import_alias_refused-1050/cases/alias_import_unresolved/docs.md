# alias_import_unresolved

The reference text this case shows (decision 1050):

> Import aliases do not exist. `from` names a package — std, a bundled package or a dependency
> declared in `botopink.json`; `"@/lib.db"` names none, so the import is refused as an unresolved
> import source (decision 242), as `check` and `build` print it. A program that loads the package
> sees the same `Diagnostic` (decision 989 (4)).
