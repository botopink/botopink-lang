# import_alias_beside_local_type

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> Without an alias the second item binds the name again (`import-name-collision`,
> decision 170); a type this module declares beside an aliased import of a
> same-named type is two types (decision 603).

This module's own `Box` beside `shapes`'s `Box` imported as `ShapeBox`: the alias tells them apart, so each is its own type in every position on every target.
