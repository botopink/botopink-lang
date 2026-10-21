# import_namespace_callable_default

The reference text this cell shows (from `conformance/docs.md`, § Imports):

> **An item that names a module always binds its namespace** (decision 582). `import
> {components.card};` binds `card`, the namespace of `components/card`: `card.Props`
> and `card.render(p)` reach its items. Written as a value — called, passed, bound
> (`card(p)`, `ps.map(card)`, `val f = card`) — the namespace is the module's `pub
> default` (§ A module's default function), with the default's function type; a module
> declares its default beside its other `pub` items. `import {components.card.render}`
> binds the item `render`, and `import {components.card: {Props, render}}` the items,
> as any path does. No item of a module ever stands in for a namespace of the same
> name: the namespace is what `import {a.b}` binds.
