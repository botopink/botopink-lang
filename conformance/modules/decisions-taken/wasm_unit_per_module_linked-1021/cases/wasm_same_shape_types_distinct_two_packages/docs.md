# wasm_same_shape_types_distinct_two_packages

A same-named, same-shaped record declared in two packages is two types on every target (decision 1027 (2)): this package's `Person` and its dependency `kin`'s, each in a module `shapes`, so their qualified names differ only in the package. `is`, `==` and print tell them apart. On wasm the brand closing each declared group hashes the package-qualified names (`<pkg>@shapes.Person`, `gcKeyTypes`); a brand over the module path and name alone makes the two one type.
