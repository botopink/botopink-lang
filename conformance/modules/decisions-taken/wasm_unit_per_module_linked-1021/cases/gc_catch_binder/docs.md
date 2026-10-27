# gc_catch_binder

The binder of `try f() catch { e -> … }` is the failure's error, a string and a record, the handler's value answering for the `try`; on wasm the GC lowering binds it to the `$result`'s payload, unboxed to the error's representation (decision 1021 (10)).
