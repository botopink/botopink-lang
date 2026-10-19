# Decision 670 — Any function declared `-> anytype` builds a type; std's `Type` functions are the first of them, not a privilege.

`view` is the program's own function, declared `-> anytype`, with only a `comptime` parameter: it reads `User`'s fields with `compiler.fields(t)`, drops `password` and builds an inline type with `compiler.buildTypeInline`. Called in a module-level `val`'s initializer, it is evaluated at build and `PublicUser` is a type — usable as `show`'s parameter type and as a constructor —, resolved through the import of `views` like any function; the checker keeps no list of std names. std's `Type.partial` is the same kind of function, no privilege: it takes the built `PublicUser` as its source and gives `UserPatch`. The program prints `Ana <ana@example.com>` and `- new@example.com`. The same call anywhere but a module-level `val`'s initializer is refused at the call, `anytype-outside-type-val`, and a run-time argument to it is `comptime-arg-not-known`.

Cells in this repository that also bear on it: `modules/decisions-taken/derived_type_static_methods-307/run/src/cases/derived_type_functions`, `modules/decisions-taken/derived_type_static_methods-307/refused/src/cases/derived_type_outside_val`.

[draft/main.bp](draft/main.bp) · [draft/views.bp](draft/views.bp)
