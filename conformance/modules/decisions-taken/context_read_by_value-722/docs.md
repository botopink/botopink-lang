# Decision 722 — A context is read through a context value the reader imports — `use context(themeContext)`, never a bare type name — answering the nearest context of that type provided above, else the default the handle carries; the handle is imported as any name, so the default is found through the import graph and nothing is searched

`theme` declares the context as a value, `themeContext`, made with `createContext` over a `Theme` default. `Card` reads it with `use context(themeContext)` — the context value it imports, never the bare type name — and `t` is a `Theme`. Rendered at the root, nothing provides a `Theme` above it, so the read answers the default the value carries and the program prints `card #e11d48`. `Dark` makes another context of the same type in its body and provides it with `use provide(dark)`; the `Card` it renders below it reads the nearest `Theme` provided above, and the program prints `dark > card #111827`. The default is found through the import of `themeContext`, like any name: nothing searches a catalogue at build. A context's identity is its type, so two contexts over one base type are two types.

Cells in this repository that also bear on it: `modules/context_default`, `modules/context_default_imported`, `modules/context_nearest_wins`, `modules/context_provide_read`.

[draft/main.bp](draft/main.bp) · [draft/theme.bp](draft/theme.bp)
