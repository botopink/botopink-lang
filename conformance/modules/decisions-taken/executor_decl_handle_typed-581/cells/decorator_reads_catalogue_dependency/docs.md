# decorator_reads_catalogue_dependency

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298)):

> A reader that a dependency declares — a decorator whose body reads the catalogue
> — answers for that dependency alone (decision 551): it is analysed after the
> other modules of its own package and before the packages that import it, so a
> module of another package imports it freely; only a module of its own package
> that imports it is `typeinfo-all-imported`.
