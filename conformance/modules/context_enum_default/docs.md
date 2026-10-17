# context_enum_default

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> **Contexts** (decisions 354, 378, 379). What a body reads from above it is a
> context, named by its value's type. std's `context.createContext(value)` makes
> one; written as a module-level `val`'s initializer it **declares** that type's
> default — `pub val themeContext = comptime createContext(Theme(mode: "light"));`
> — one declaration per type in the program (`context-declared-twice` at the
> second, naming the first), and a module-level `Context<T>` made any other way
> (a `val` naming another context, a `var`) is `context-not-declared`. Two
> contexts over one base type are two types (`type Depth(n: i32)`, `type
> Step(n: i32)`). Two hooks of std's `context` module work it, `use`d and nothing
> else (`context-hook-without-use`):
