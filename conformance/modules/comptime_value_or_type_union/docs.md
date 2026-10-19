# comptime_value_or_type_union

The reference text this cell shows (from `conformance/docs.md`, § Generics):

> A `comptime` parameter may take **a value or a type** (decisions 297, 575 (5), 736):
> `comptime source: Atom<T> | type<T>` — one function, one name, two forms. An
> `Atom<T>` argument binds `T` from it (or `T` is written, `atomKey<User>(currentUser)`,
> and checked); a type argument binds `T` to that type; the body tells them apart with
> `source is type<T>` (the bare `source is type` too), decided while the program compiles —
> only the branch taken is emitted, and where the test holds, reading `source` is
> `type-arg-read`.
