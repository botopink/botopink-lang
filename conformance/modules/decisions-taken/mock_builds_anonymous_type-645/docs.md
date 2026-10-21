# Decision 645 — `mock(Greeter)` builds an anonymous type: an inline type implementing the behavior, `compiler.buildTypeInline(fields: [Field("__id", string)], implements: [t])`, given its methods by `addMember` and instantiated — no `"Mock"` name, no `addType`; and an inline type may `implement` a behavior.

The decision fixes how std's `mock(Greeter)` is built, and the example builds the same shape by hand, as a function of
its own, `stub`, in [draft/comptime/stubs.bp](draft/comptime/stubs.bp). `compiler.buildTypeInline` builds an
anonymous inline type — one field, `__id`, and `implements: [t]`, so the inline type implements the behavior `t` names
and its members are checked against the contract as a nominal type's are. `compiler.addMember(M, …)` then gives it one
method per member of the behavior, the form with the built type first that is legal outside a decorator; no `"Mock"`
name is given and no `addType` runs. The function answers `M(__id: "stub")`, a `T` by the contract with the type itself
unnamed. Every parameter is `comptime`, so the call in `main` is expanded where it stands, and the value goes wherever a
`Greeter` goes: `greetBoth` prints `fixed Ana, fixed Ana`.

[draft/main.bp](draft/main.bp)
