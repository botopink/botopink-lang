# import_two_types_one_name

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> Two same-named types of two modules
> are two types when each is imported under an alias, or one of the two is
> (decision 310): `import {a.p.Policy as APolicy}; import {b.p.Policy as
> BPolicy};` — each alias names its own type in every type and value position,
> a function of either module taking or answering its `Policy` takes or answers
> that alias's type, `is` tells them apart, and each value prints as declared.

Two records declared `Policy` in `a/p` and `b/p`, each imported under an alias: each constructs, prints, reads its fields and answers its own method, `is` tells them apart, and `a/p`'s functions take and answer `APolicy`, on every target.
