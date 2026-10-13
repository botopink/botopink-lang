# import_same_type_name_two_packages_one_aliased

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> Two same-named types of two modules
> are two types when each is imported under an alias, or one of the two is
> (decision 310): `import {a.p.Policy as APolicy}; import {b.p.Policy as
> BPolicy};` — each alias names its own type in every type and value position,
> a function of either module taking or answering its `Policy` takes or answers
> that alias's type, `is` tells them apart, and each value prints as declared.

Two packages each declare `App`, one imported plain and one under an alias: `site`'s `makeSite() -> App` answers a `SiteApp`, each answers its own method and prints as declared, and `is` tells them apart, on every target.
