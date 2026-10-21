# typeinfo_lowercase

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298)):

> `@typeInfo` is the one reflection builtin (decision 248): `.name` reads a
> declaration, `.meta(T)` / `.metaAll(T)` its
> typed meta (§ Typed meta), the static `@TypeInfo.all(…)` of
> its type the program (decision 253; `@typeInfo.all` is `typeinfo-all-on-function`),
> and `@typeInfo(T)` used as a value is a `TypeInfo<T>` (decision 253; its members
> other than `name` and `meta` are `typeinfo-unknown-member` until they are answered). The lowercase
> `@typeinfo` is `typeinfo-lowercase`, naming `@typeInfo`.
