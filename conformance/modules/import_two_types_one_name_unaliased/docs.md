# import_two_types_one_name_unaliased

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> Without an alias the second item binds the name again (`import-name-collision`,
> decision 170), and a type this module declares beside an aliased import of a
> same-named type is refused too (question B-23-a).

`a/p`'s and `b/p`'s `Policy` imported with no alias: the second item is refused, naming both, on every target.
