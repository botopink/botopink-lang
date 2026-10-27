# Decision 1021 — 1017's units are core modules composed by the compiler, with one runtime unit and canonical types; answers 1017-b (1)–(8) (a); amends 1017 (1), (3), 334, 518.

The wasm GC lowering answers for a program where it fell back to linear memory before (1021 (10)): a `catch { e -> … }`
binder (`gc_catch_binder`), `try f() catch null` into a declared optional (`gc_catch_null_into_optional`), an `if`
answering `null` or a value (`gc_if_null_into_optional`), a `bigint` (`gc_bigint_values`, 1021 (8)) and string ordering
(`gc_string_ordering`), a `case` arm that assigns a local (`gc_case_arm_assigns`), a `?.` read of a field typed an
array, a tuple or an optional array (`gc_optional_field_payload`), a behavior-typed value (`gc_behavior_values`),
`f?.(x)` answering a plain value (`gc_optional_call_link`), `val assert` over a reference (`gc_val_assert_subject`), a
return written through an alias of a `Result` (`gc_result_alias_return`) and a tuple parameter's pattern
(`gc_param_destructure`). Declarations of one shape stay distinct types, one package's and two packages' alike
(`wasm_same_shape_types_distinct`, decision 1027), and two packages' `Person` in modules of one path, told apart by the
package alone (`wasm_same_shape_types_distinct_two_packages`, 1027 (2)). Each case answers on wasm as on the other
targets; the wasm answers are also pinned by `modules/compiler-core`'s wasm codegen tests, a wasm conformance module not
running yet.

[cases/gc_catch_binder/src/main.bp](cases/gc_catch_binder/src/main.bp)
[cases/gc_catch_null_into_optional/src/main.bp](cases/gc_catch_null_into_optional/src/main.bp)
[cases/gc_if_null_into_optional/src/main.bp](cases/gc_if_null_into_optional/src/main.bp)
[cases/gc_bigint_values/src/main.bp](cases/gc_bigint_values/src/main.bp)
[cases/gc_string_ordering/src/main.bp](cases/gc_string_ordering/src/main.bp)
[cases/gc_case_arm_assigns/src/main.bp](cases/gc_case_arm_assigns/src/main.bp)
[cases/wasm_same_shape_types_distinct/src/main.bp](cases/wasm_same_shape_types_distinct/src/main.bp)
[cases/wasm_same_shape_types_distinct_two_packages/src/main.bp](cases/wasm_same_shape_types_distinct_two_packages/src/main.bp)
[cases/gc_optional_field_payload/src/main.bp](cases/gc_optional_field_payload/src/main.bp)
[cases/gc_behavior_values/src/main.bp](cases/gc_behavior_values/src/main.bp)
[cases/gc_optional_call_link/src/main.bp](cases/gc_optional_call_link/src/main.bp)
[cases/gc_val_assert_subject/src/main.bp](cases/gc_val_assert_subject/src/main.bp)
[cases/gc_result_alias_return/src/main.bp](cases/gc_result_alias_return/src/main.bp)
[cases/gc_param_destructure/src/main.bp](cases/gc_param_destructure/src/main.bp)
