# Decision 722 — A context is read through a context value the reader imports — `use context(themeContext)`, never a bare type name — answering the nearest context of that type provided above, else the default the handle carries; the handle is imported as any name, so the default is found through the import graph and nothing is searched

`theme` declares the context as a value, `themeContext`, made with `createContext` over a `Theme` default. `Card` reads it with `use context(themeContext)` — the context value it imports, never the bare type name — and `t` is a `Theme`. Rendered at the root, nothing provides a `Theme` above it, so the read answers the default the value carries and the program prints `card #e11d48`. `Dark` makes another context of the same type in its body and provides it with `use provide(dark)`; the `Card` it renders below it reads the nearest `Theme` provided above, and the program prints `dark > card #111827`. The default is found through the import of `themeContext`, like any name: nothing searches a catalogue at build. A context's identity is its type, so two contexts over one base type are two types.

Cells in this repository that also bear on it: `modules/decisions-taken/context_named_by_value_type-379/cases/context_default`, `modules/decisions-taken/context_read_by_value-722/cases/context_default_imported`, `modules/decisions-taken/context_named_by_value_type-379/cases/context_nearest_wins`, `modules/decisions-taken/component_wrapper_and_contexts-354/cases/context_provide_read`.


[cases/context_default_imported/src/main.bp](cases/context_default_imported/src/main.bp)
[cases/context_read_by_type_refused/src/main.bp](cases/context_read_by_type_refused/src/main.bp)

Proved also by [context_read_by_value](../context_provide_made_in_body-723/cases/context_read_by_value/src/main.bp)
Proved also by [context_read_of_parameter](../context_provide_made_in_body-723/cases/context_read_of_parameter/src/main.bp)
