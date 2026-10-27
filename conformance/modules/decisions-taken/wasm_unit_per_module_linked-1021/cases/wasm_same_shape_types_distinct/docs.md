# wasm_same_shape_types_distinct

Declarations of one shape stay distinct types on every target (decision 1027): `Person` and `Vec`, `Box<T>` and `Maybe.Some`, and this package's `Person` and the one its dependency `other` declares alike — `is`, a `case` arm, `==` and print tell them apart. On wasm each declared type group ends with a brand type, a hash of its members' package-qualified names (`<pkg>@<path>.<Type>`, `gcKeyTypes`), so two groups of one shape are never one type.
