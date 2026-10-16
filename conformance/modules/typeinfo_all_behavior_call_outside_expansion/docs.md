# typeinfo_all_behavior_call_outside_expansion

The reference text this cell shows (from `conformance/docs.md`, § Comptime, Typed meta (decision 298)):

> **A decorator names the behavior its declarations implement** (decision 564).
> `pub fn module(comptime decl: @Decl<Module>) { … }`, `Module` a `behavior`:
> `#[module]` on a type that does not `implement Module` is refused at the
> annotation, naming the type and the behavior (`` `#[module]` needs a type
> implementing `Module` — `City` does not ``). `@TypeInfo.all(with: module)`
> answers `Declared<Module>[]`, with no `member:`; a query over several
> decorators answers the behavior they all name, and `Declared<unknown>[]` when
> they name different ones; a decorator whose `@Decl` names no behavior answers
> `Declared<unknown>[]` as above (`member:` still names a type's associated fn
> there). The annotation is the opt-in: implementing a behavior catalogues no
> type by itself. Calling a function of the behavior on an entry's `value`
> (`d.value.make()`) is legal only inside a function expanded at its call site
> (decision 562, below), where each entry is a concrete type; elsewhere it is
> refused at the call.

<!-- example: modules/typeinfo_all_behavior_call_outside_expansion -->
