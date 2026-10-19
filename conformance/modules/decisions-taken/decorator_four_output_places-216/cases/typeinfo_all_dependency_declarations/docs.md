# typeinfo_all_dependency_declarations

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298)):

> The catalogue's reach is the build, not the program's imports: a declaration
> carrying `d` in a dependency — one the package declares, or one a dependency
> declares — is an entry of the program's queries though no module of the program
> imports it, so declaring a package in `botopink.json` is all a program does for
> what that package contributes to be listed, and removing the dependency removes
> its entries. The entry's `module` is the dependency's module path,
> `<package>/<module>`, ordered with the others by it. A dependency read back from
> the code cache answers the entries its analysis recorded, with their meta, as
> one analysed again does: the program's catalogue is the union of every
> package's.
