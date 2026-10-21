# component_use

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> **Expression role.** `Component<R>` is the one wrapper of `use` (decisions
> 104, 118, 128, 354). A function returning it is a **component** when its `R`
> implements the marker `Renderable` (`type Element(…) implement Renderable`):
> a component is **called** (`Widget(1)`, or as a tag), never `use`d. Any other
> `Component<R>` is **read with `use`** — what React calls a hook: `val x = use
> <f>(…)` runs it and binds `R`, a bare `use <f>(…);` runs one whose `R` is
> `void`, and `val {a, b} = use …` binds `R`'s fields by name. Such a function is
> named by its noun (`state`, `effect`, `router`, `pathname` — never
> `useState`), because the keyword *is* the activation. The body that `use`s is
> itself a `Component` function — another one read with `use` (they compose) or
> a component, which may `await` too. There is no annotation: the return is the
> declaration of the effect (decision 118), and there is no base: any
> `Component` may be `use`d in any `Component` body.
