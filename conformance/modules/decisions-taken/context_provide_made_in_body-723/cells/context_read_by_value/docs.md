# context_read_by_value

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - `val t = use context(themeContext);` reads through a context value the module
>   declares or imports (`import {theme.themeContext};`): it answers the nearest
>   context of `themeContext`'s type, `Theme`, provided above, else
>   `themeContext`'s own default — no read is unbound, and nothing is searched:
>   the default is the value the read names. A bare type name, `use
>   context(Theme)`, is `context-read-by-type` at the argument, naming the form
>   `use context(<a context value>)`; a value that is no module-level name (a
>   parameter, a local) is `context-not-declared` at the argument.
