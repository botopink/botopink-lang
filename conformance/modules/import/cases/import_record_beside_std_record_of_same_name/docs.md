# import_record_beside_std_record_of_same_name

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> What an item binds is its **leaf** — `name`,
> `seven` — never the segments before it

> A folder of std is no module and is not
> importable (decision 919): `import {io} from "std"` is refused, located, naming
> the leaves (`import {io.fs}`); a module namespace reaches its types, so `import {collections} from "std"`
> allows `collections.Dict.empty()` beside `collections.lt()` (decision 111's
> constructors are type-scoped).

`import {collections} from "std"` binds `collections`, never `collections.Queue`: the
`Queue` in scope is the one `import {items.Queue} from "shelf"` names, on every target.
