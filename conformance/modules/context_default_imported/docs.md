# context_default_imported

The reference text this cell shows (from `conformance/docs.md`, § use — imports, activation, and hooks):

> - `val t = use context(Theme);` reads the context of type `Theme` provided
>   nearest above, else `Theme`'s declared default — no read is unbound. A type
>   with no declared default is `context-not-declared` at the read; the
>   declaration is found in the reading module, or in a module analysed before
>   it — the type's own module included (question B-17-g).
