# import_two_types_one_name_unaliased

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> Without an alias the second item binds the name again (`import-name-collision`,
> decision 170); a type this module declares beside an aliased import of a
> same-named type is two types (decision 603), the alias the other module's type here,
> a std type's included (`own_type_beside_std_type_import`).

`a/p`'s and `b/p`'s `Policy` imported with no alias: the second item is refused, naming both, on every target.
