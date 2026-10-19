# context_default

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - `use provide(ctx);` in a **component's** body gives the context value `ctx`
>   to everything that component renders below it — descendants only, never
>   itself or a sibling; the nearest provider of a type wins. It takes the
>   context alone: a body that provides another value makes a context of the
>   same type in its body — `use provide(createContext(Theme(mode: "dark")));`,
>   or `val c = comptime createContext(Theme(mode: "dark"));` then `use
>   provide(c);` — and `use provide(themeContext)` gives the declared default
>   again. In a body whose `R` is not `Renderable` it is
>   `context-provide-outside-component`, and after the body rendered a component
>   it is `context-provide-after-render` (that child would not see it).
> - `val t = use context(themeContext);` reads through a context value the module
>   declares or imports (`import {theme.themeContext};`): it answers the nearest
>   context of `themeContext`'s type, `Theme`, provided above, else
>   `themeContext`'s own default — no read is unbound, and nothing is searched:
>   the default is the value the read names. A bare type name, `use
>   context(Theme)`, is `context-read-by-type` at the argument, naming the form
>   `use context(<a context value>)`; a value that is no module-level name (a
>   parameter, a local) is `context-not-declared` at the argument.
