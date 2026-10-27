# gc_result_alias_return

A function whose return is written through an alias of a `Result` (`-> Parser<i32>`, decision 118) answers that `Result`, read by `try … catch`, `unwrapOr` and `isError`; on wasm the GC lowering reads the return as the `Result` the alias names (decision 1021 (10)).
