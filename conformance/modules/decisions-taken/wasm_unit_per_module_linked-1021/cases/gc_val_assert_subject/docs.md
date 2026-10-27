# gc_val_assert_subject

`val assert P = e [catch d]` over a variant, a record and a `Result` binds the pattern's names, the `catch` value standing for `e` where the pattern does not match; on wasm the GC lowering keeps the subject as the reference it is (decision 1021 (10)).
