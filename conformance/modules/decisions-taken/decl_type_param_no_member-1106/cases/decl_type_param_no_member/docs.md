# decl_type_param_no_member

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A `decl` typed by a bare type parameter (`<T>(syntax decl: T)`) has no member,
> as `syntax decl: unknown` has none (decision 1106): `decl.make()` in a tree is
> the checker's refusal, located at the call, and `decl` is only handed on to
> another parameter typed by the same `T`; a member is read through a declared
> contract or from the value the decorator built.
