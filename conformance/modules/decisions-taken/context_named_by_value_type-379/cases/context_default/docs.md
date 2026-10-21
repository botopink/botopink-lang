# context_default

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
> - `val t = use context(themeContext);` reads through a context value the module
>   declares or imports (`import {theme.themeContext};`): it answers the nearest
>   context of `themeContext`'s type, `Theme`, provided above, else
>   `themeContext`'s own default — no read is unbound, and nothing is searched:
>   the default is the value the read names. A bare type name, `use
>   context(Theme)`, is `context-read-by-type` at the argument, naming the form
>   `use context(<a context value>)`; a value that is no module-level name (a
>   parameter, a local) is `context-not-declared` at the argument.
