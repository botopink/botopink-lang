# Decision 903 — A `#[compiler.beamMemory(.PersistentTerm)]` var's `x = f(x)` is atomic on the BEAM as an `.Ets` one's is (547 (ii)): the runtime runs read, compute, `persistent_term:put` under a per-`var` lock it holds and releases however the writer ends; no write is lost on any holding; reads stay `persistent_term:get`, lock-free; a plain `x = v` is one `put`; the reference states the write's cost — the scan and the lock.

[cases/persistent_term_var_write_atomic/src/main.bp](cases/persistent_term_var_write_atomic/src/main.bp)
