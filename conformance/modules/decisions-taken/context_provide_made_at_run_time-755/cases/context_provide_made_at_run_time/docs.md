# context_provide_made_at_run_time

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - `use provide(ctx);` in a **component's** body gives the context value `ctx`
>   to everything that component renders below it — descendants only, never
>   itself or a sibling; the nearest provider of a type wins. It takes the
>   context alone: a body that provides another value makes a context of the
>   same type in its body — `use provide(createContext(Theme(mode: "dark")));`,
>   or `val c = comptime createContext(Theme(mode: "dark"));` then `use
>   provide(c);`, or, for a value known only at run time, `val c = use memo({ ->
>   createContext(Theme(mode: mode)) });` then `use provide(c);` (made on the
>   first render of the memo's cell and kept while it stands) — and `use
>   provide(themeContext)` gives the declared default again.
