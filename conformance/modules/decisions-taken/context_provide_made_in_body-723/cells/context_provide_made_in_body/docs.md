# context_provide_made_in_body

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - `use provide(ctx);` in a **component's** body gives the context value `ctx`
>   to everything that body resolves after it — descendants only, never
>   itself or a sibling; the nearest provider of a type wins. It counts in the
>   order written, after a `use` too: a component resolved at an earlier `use`
>   does not see it, one resolved later does (decision 812 (3)), and a child's
>   own provide reaches its subtree alone. It takes the
>   context alone: a body that provides another value makes a context of the
>   same type in its body — `use provide(createContext(Theme(mode: "dark")));`,
>   or `val c = comptime createContext(Theme(mode: "dark"));` then `use
>   provide(c);`, or, for a value known only at run time, `val c = use memo({ ->
>   createContext(Theme(mode: mode)) });` then `use provide(c);` (made on the
>   component instance's first render and kept for it) — and `use
>   provide(themeContext)` gives the declared default again. In a body that is no
>   `component` body answering `Component<R>` it is
>   `context-provide-outside-component`.
