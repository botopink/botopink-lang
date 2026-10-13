# context_default

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - `use provide(createContext(value));` in a **component's** body gives the
>   context to everything that component renders below it — descendants only,
>   never itself or a sibling; the nearest provider of a type wins (`use
>   provide(themeContext)` gives the declared default again).
> - `val t = use context(Theme);` reads the context of type `Theme` provided
>   nearest above, else `Theme`'s declared default — no read is unbound.
