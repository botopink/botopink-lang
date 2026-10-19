# init_executor_handle_mistyped

The reference text this cell shows (from `conformance/docs.md`, § Decorators):

> The declared type of the `syntax decl` parameter is the contract the
> annotated declaration meets (decision 716), and every tree the decorator
> writes — an executor, a member — is checked once, at the decorator, against
> that type, never per annotated declaration. `syntax decl: unknown` admits any
> declaration and gives `decl` no member: `decl.make()` in a tree is the
> checker's own refusal at the decorator, and `decl` serves only where an
> `unknown` does and in the `compiler.*` reads. `syntax decl: Module`, a
> behavior, admits a type implementing it — `#[module]` on a type without
> `implement Module` is refused at the annotation, naming the type and the
> behavior — and types `decl.make()` by the behavior; `syntax decl: fn() ->
> string` admits a function of that type, `decl` callable; `syntax decl: T`
> admits any declaration and keeps its type. Inside the executor the handle is
> the annotated declaration itself as a run-time value (decision 581 (2)):
> `add(Module(name: name, lifecycle: lifecycle, make: decl))` under `syntax decl:
> fn() -> string` is checked against `make`'s type at the decorator, and a
> declaration that does not meet the contract is refused at its annotation.
