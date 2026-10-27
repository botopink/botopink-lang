# Decision 1021 — 1017's units are core modules composed by the compiler, with one runtime unit and canonical types; answers 1017-b (1)–(8) (a); amends 1017 (1), (3), 334, 518.

The wasm GC lowering answers for a program where it fell back to linear memory before (1021 (10)): a `catch { e -> … }`
binder (`gc_catch_binder`), `try f() catch null` into a declared optional (`gc_catch_null_into_optional`), an `if`
answering `null` or a value (`gc_if_null_into_optional`), a `bigint` (`gc_bigint_values`, 1021 (8)) and string ordering
(`gc_string_ordering`). Declarations of one shape stay distinct
types, one package's and two packages' alike (`wasm_same_shape_types_distinct`, decision 1027). Each case answers on
wasm as on the other targets; the wasm answers are also pinned by `modules/compiler-core`'s wasm codegen tests, a wasm
conformance module not running yet.

[cases/gc_catch_binder/src/main.bp](cases/gc_catch_binder/src/main.bp)
[cases/gc_catch_null_into_optional/src/main.bp](cases/gc_catch_null_into_optional/src/main.bp)
[cases/gc_if_null_into_optional/src/main.bp](cases/gc_if_null_into_optional/src/main.bp)
[cases/gc_bigint_values/src/main.bp](cases/gc_bigint_values/src/main.bp)
[cases/gc_string_ordering/src/main.bp](cases/gc_string_ordering/src/main.bp)
[cases/wasm_same_shape_types_distinct/src/main.bp](cases/wasm_same_shape_types_distinct/src/main.bp)
