# context_provided_and_read_across_packages

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> **Contexts** (decisions 354, 378, 379, 722, 723). What a body reads from above
> it is a context; its identity is its value's type. std's
> `context.createContext(value)` makes one; written as a module-level `val`'s
> initializer it **declares** a context value carrying that type's default —
> `pub val themeContext = comptime createContext(Theme(mode: "light"));` — one
> declaration per type in the program (`context-declared-twice` at the second,
> naming the first), and a module-level `Context<T>` made any other way (a `val`
> naming another context, a `var`) is `context-not-declared`.
