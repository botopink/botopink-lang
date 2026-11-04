# decl_in_type_position

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> Inside an added member `decl` names the annotated declaration in a type
> position too (decision 627): `fn() -> decl` and `fn(c: decl) -> decl` are
> checked once, at the decorator, against the handle's contract, and on `City`
> they are `fn() -> City` and `fn(c: City) -> City`.
