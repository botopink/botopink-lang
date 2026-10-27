# Decision 46 — `d["k"]` on a `Dict` routes to `lookup`

`stock` is a `Dict<string, i32>` holding `apple` and `pear`. `stock["apple"]` reads the dictionary and prints `3` on
every target, with no `undefined` on commonJS and no `bp_unsupported_index` abort on erlang. A key holding `0` reads
`0`. `stock["plum"]` is a key the dictionary does not hold: the index answers `null`, the one spelling of absence, so
`?? -1` gives the fallback. The index is the dictionary's own read. Under decision 63's amendment that read is the
method `at`, which `Dict` provides through the ambient `Index<K, V>`, so `stock["apple"] == stock.at("apple")` is `true`.
The key may be any expression of the key type: a computed `"pear"` reads the same entry.

Cells in this repository that also bear on it: `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_dict`,
`modules/optional/cases/optional_chain_method_on_dict_field`.

[draft/main.bp](draft/main.bp)
