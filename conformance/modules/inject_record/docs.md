# inject_record

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> **Dependency injection** rides the context tree (decision 416). `val deps = use
> inject(Deps);` builds the record `Deps`, each field the nearest context of its
> field's type provided above, else that type's declared default, else the field's
> own default — a field with none of the three is `context-not-declared` at the
> `inject`, naming the field; `inject` of a behavior or of any type that is no
> record is `inject-not-record` (a behavior is read with `use context(B)`). A
> second argument of `createContext` names the behavior the context is provided
> as — `createContext(PgRepository(pool), Repository)`, the value checked to
> implement it as a parameter typed `Repository` is, through its own `implement`
> clause or a behavior that `extends` `Repository` (`context-behavior-not-implemented`
> at the argument) — so `use
> context(Repository)` and an `inject` field typed `Repository` read it; its
> declaration is the behavior's default. Providing stays one context per
> dependency, so a test's root swaps one.
