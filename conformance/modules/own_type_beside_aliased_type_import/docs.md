# own_type_beside_aliased_type_import

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> Without an alias the second item binds the name again (`import-name-collision`,
> decision 170), and a type this module declares beside an aliased import of a
> same-named type is refused too (question B-23-a).

This module's own `Box` beside `shapes`'s `Box` imported as `ShapeBox` is refused at the import, naming both, on every target — today's answer while question B-23-a is open.
