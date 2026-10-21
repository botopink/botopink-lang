# context_nearest_wins

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - `use provide(createContext(value));` in a **component's** body gives the
>   context to everything that body resolves after it — descendants only,
>   never itself or a sibling; the nearest provider of a type wins (`use
>   provide(themeContext)` gives the declared default again). In a body that is no
>   `component` body answering `Component<R>` it is
>   `context-provide-outside-component`.
