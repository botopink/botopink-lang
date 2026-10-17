# import_two_types_one_name_reached_indirectly

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

`a/p`'s `Policy` reaches the module through a namespace call (`pa.slow()`), an imported template's built code (`quick("x")`) and a member `a/p`'s decorator adds (`policy()`): each answers an `APolicy`, beside `b/p`'s `BPolicy`, on every target.
