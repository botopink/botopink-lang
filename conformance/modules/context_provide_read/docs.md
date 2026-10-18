# context_provide_read

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - `use provide(ThemeContext, value);` in a **component's** body gives `value`
>   to everything that component renders below it — descendants only, never
>   itself or a sibling; the nearest provider wins. In a body whose `R` is not
>   `Renderable` it is `context-provide-outside-component`, and after the body
>   rendered a component it is `context-provide-after-render` (that child would
>   not see it).
> - `val t = use context(ThemeContext);` reads the value provided nearest above
>   — a `Theme`; with no provider above it is `context-unbound` at run time.
