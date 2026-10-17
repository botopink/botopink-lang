# implement_clause_for

The reference text this cell shows (from `conformance/docs.md`, § Decided, not yet implemented):

> These forms are **deliberately absent**, so that none reads as unfinished work:
>
> | Form | What the compiler says |
> |---|---|
> | `implement A for P { … }` after a bodyless `type P(…)` | `error[implement-clause-for]` — the type's own clause is `type P(…) implement A { … }` |
