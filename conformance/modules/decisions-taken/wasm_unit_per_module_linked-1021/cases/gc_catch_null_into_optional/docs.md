# gc_catch_null_into_optional

`try f() catch null` into a declared `?T` is absent when `f()` fails; on wasm the GC lowering answers the optional's own representation — a scalar payload boxed, a reference payload its nullable reference (decision 1021 (10)). The linear fallback answered `0` for the absent `?i32`.
