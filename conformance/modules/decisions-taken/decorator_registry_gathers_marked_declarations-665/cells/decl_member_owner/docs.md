# decl_member_owner

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> A member's `@Decl` names its owner (decision 526): `decl.owner` is the
> `Declared<unknown>` of the type or behavior that holds the annotated method or
> field — its `name`, its `module`, its `value` `null` as in every decorator
> body — and `null` for a module-level declaration. A registration a member's
> decorator emits is named through it (`decl.owner!.name + "_" + decl.name`), so
> two same-named members of two types never collide.
