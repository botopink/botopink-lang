# Decision 174 — † `Dict.ofEntries(entries: Array<#(K, V)>) -> Dict<K, V>` in `libs/std/src/collections.bp`; a key that repeats keeps its

`Dict.ofEntries` is std's constructor of a `Dict` from an array of `#(key, value)` tuples, declared in `collections.bp`
beside `Set.fromList` and `Queue.fromList`, which keep their names. A key that repeats keeps its last value, as
`insert` does. In the example the entries name `a` twice, first with `1` and then with `3`, so the dict holds two keys:
`size()` prints `2`, `a` reads `3` and `b` reads `2`. The same dict built by `insert` calls in the same order is equal to
it under `==`, which prints `true`. The answer is the same on every target.

[draft/main.bp](draft/main.bp)
