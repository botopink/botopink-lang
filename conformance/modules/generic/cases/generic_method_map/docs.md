# generic_method_map

The reference text this cell shows (from `conformance/docs.md`, § Generics):

> A written generic type carries all of its type arguments — `fn get(b: Box)` for a
> `type Box<T>` is `error: Box needs 1 type argument`, and `Pair<i32>` for a
> `Pair<A, B>` names both counts. Inside a declaration with type parameters `Self`
> carries them too: `Self<T>`, and `Self<U>` for the same type over another
> argument. A declaration without type parameters writes `Self`, and so does a
> non-generic type implementing a generic behavior — the behavior's `Self<…>` is
> that type:
