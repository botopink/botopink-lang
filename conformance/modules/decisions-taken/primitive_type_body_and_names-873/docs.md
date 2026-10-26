# Decision 873 — A primitive type's body declares a property as `val length: i32;`, a form of `primitives.bp` alone; a local shadows a primitive type's statics in its body; a module-level `fn` / `val` named like any lowercase type — `array` included — is `primitive-type-name-taken`; a failed `toUtf8` names `bytes.toUtf8`.

A property — `pub val length: i32;` in `pub type array<T> { … }` — is a form of std's `primitives.bp` alone: a `val` in any other type body is a parse error, whatever the type's name. A local or a parameter named like a primitive type shadows the type in its body, statics included: `bytes.fromUtf8(s)` there is a method call on the value. A module-level `fn` or `val` named like a lowercase type — `array` included — is `primitive-type-name-taken`. A failed `toUtf8` answers `Error("bytes.toUtf8: not valid UTF-8")` on every target (`bytes_round_trip`).

[cases/primitive_property_outside_prelude_refused/src/main.bp](cases/primitive_property_outside_prelude_refused/src/main.bp)
[cases/primitive_static_shadowed_by_local/src/main.bp](cases/primitive_static_shadowed_by_local/src/main.bp)
[cases/primitive_static_on_local_is_method/src/main.bp](cases/primitive_static_on_local_is_method/src/main.bp)
[cases/primitive_type_name_taken_array/src/main.bp](cases/primitive_type_name_taken_array/src/main.bp)
