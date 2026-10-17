# beam_memory_ets_keyed_bump

The reference text this cell shows (from `conformance/docs.md`, § @BeamMemory — where a module var lives on the BEAM):

> **`Ets`** — one value per node, in a named public ETS table the module owns
> through a registered owner process, so the table survives the process that
> first touched it and is re-created and re-seeded from the declaration if the
> owner dies. `hits += 1` and `hits = hits + 1` on an `i32` or `i64` are one
> atomic `ets:update_counter`; any other read-modify-write — `hits = hits * 2 +
> 1`, or `+=` on an `f64`, `bool` or `string` — is refused, because two processes
> running it would lose one of the two writes. The initialiser must be a literal
> or a `comptime` expression: it is re-run at a moment nobody chose. **`Ets` is
> cache and counting memory, not where the truth lives** — a balance, an order, a
> paid session belong in a supervised process or a database. Under **`keyed:
> false`** (the default) a `Dict` is stored as **one** value: a write copies the
> whole dict, and two processes writing *different* keys at the same time lose one
> of the writes — measured, 20 000 writes each to two keys finished at `19 996`
> and `20 000`. Under **`keyed: true`** each key is its own row: the seed is
> `Dict.empty()` or `Dict.ofEntries([#("a", 1)])` of literals, a row is read as
> `counts.at(k)`, written as `counts = counts.insert(k, v)` and counted as
> `counts = counts.bump(k, n)` (`Dict.bump`, integer values, an absent key counting from 0 — one
> atomic `ets:update_counter`, so concurrent bumps of one key lose none), and nothing else
> names the var — measured, two processes writing 20 000 times each to their own
> key finish at `20000` and `20000`; at 10 keys a write is 5× cheaper, at 10 000
> keys 5 000×. Choose `keyed: true` whenever more than one process writes; keep
> the default when the dict is replaced whole.
