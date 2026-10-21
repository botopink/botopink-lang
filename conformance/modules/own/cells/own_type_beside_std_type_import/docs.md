# own_type_beside_std_type_import

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> a type this module declares beside an aliased import of a
> same-named type is two types (decision 603), the alias the other module's type here,
> a std type's included (`own_type_beside_std_type_import`).

This module's own `Dict` beside std's `Dict` imported as `D`: the alias tells them apart, so each constructs, answers its methods and prints as its own type on every target.
