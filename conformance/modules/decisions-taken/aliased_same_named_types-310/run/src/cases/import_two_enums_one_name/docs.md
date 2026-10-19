# import_two_enums_one_name

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> Two same-named types of two modules
> are two types when each is imported under an alias, or one of the two is
> (decision 310): `import {a.p.Policy as APolicy}; import {b.p.Policy as
> BPolicy};` — each alias names its own type in every type and value position,
> a function of either module taking or answering its `Policy` takes or answers
> that alias's type — called by name, through a module namespace (`pa.slow()`),
> from an imported template's built code or a decorator's member alike —, `is`
> tells them apart, and each value prints as declared. A std type is one of the
> two as well (`import {collections.Dict as D} from "std";` beside `import
> {kit.Dict as KitDict};`).

Two enums declared `Signal` in `a/e` and `b/e`, each imported under an alias: each builds and matches its own variants, `a/e`'s and `b/e`'s functions answer their own, each prints as declared, and `is` tells them apart, on every target.
