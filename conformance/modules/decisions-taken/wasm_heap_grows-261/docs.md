# Decision 261 — The wasm heap grows: every allocation goes through a helper that calls `memory.grow` when the heap passes `memory.size`

[cells/heap_grows_past_one_page/src/main.bp](cells/heap_grows_past_one_page/src/main.bp)

Proved also by [std_hash_on_every_target](../content_hash_folds_codepoints-260/cells/std_hash_on_every_target/src/main.bp)
