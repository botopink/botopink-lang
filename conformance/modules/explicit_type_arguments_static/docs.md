# explicit_type_arguments_static

The reference text this cell shows (from `conformance/docs.md`, § Generics):

> Type arguments may be written at a use, adjacent to the name. A function or a
> constructor takes them before its call (`first<string>([], "none")`,
> `Box<i32>(value: 1)`); a type's name takes them before a member too — a
> **type application**: `Dict<string, i32>.empty()` calls `empty` on
> `Dict<string, i32>`, and `Slot<i32>.Empty` is that `Slot<i32>`. The list is read
> as type arguments only after a type's name (an upper-case first letter) and
> only when its `>` is followed by `.` or `(`; anywhere else `<` is a comparison,
> so `a < b`, `x < y && z > w` and `f(a < b, c > d)` mean what they say.
