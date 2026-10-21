# persistent_term_var_write_atomic

The reference text this cell shows (from `conformance/docs.md`, § `compiler.beamMemory` — where a module var lives on the BEAM):

> **`PersistentTerm`** — one value per node, for a `var` written rarely and read much:
> a read costs a function call, lock-free; a write is allowed and unchecked, and
> its cost is two: it scans every process heap (547), and a reassignment that reads
> the `var` (`x = f(x)`) also takes the `var`'s lock — read, compute, `persistent_term:put`
> under it — so it is atomic as an `Ets` one's is and no write is lost; the lock is
> released however the writer ends, a writer that dies included (decision 903). A plain
> `x = v` is one `put`, no lock. The cost is the writer's to weigh:
