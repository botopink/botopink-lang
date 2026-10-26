# decorator_entity_table

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A member or an associated type from a field's or a method's decorator belongs
> to the type that owns it; a function and a module-level `val` have none
> (`decorator-member-without-type`, `decorator-type-without-owner`). A decorator
> on a `val` runs like one on a `fn` (decision 356): `compiler.kind(decl)` is
> `DeclKind.Val`, `compiler.returnType(decl)` the declared type as written (`""` when
> none), `setMeta` is legal, and the `val` is an entry of `@TypeInfo.all` — one
> query answers functions, `val`s or types, never two of them
> (`typeinfo-all-mixed`). A decorator adds and never replaces: a name
> the type already has is `decorator-member-duplicate` / `decorator-type-duplicate`.
> Meta describes a top-level declaration — a `type`, a `behavior`, a `fn` or a `val`
> (`decorator-meta-on-member` from a field's or a method's decorator).
> A record-shaped type's members are closed: a call through the type names an
> associated fn it declares, by hand or through `compiler.addMember`, and any other
> name is `unknown-associated-fn` where the call is written.
