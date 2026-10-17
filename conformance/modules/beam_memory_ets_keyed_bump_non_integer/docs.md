# beam_memory_ets_keyed_bump_non_integer

The reference text this cell shows (from `conformance/docs.md`, § @BeamMemory — where a module var lives on the BEAM):

> `bump` is atomic only on integer rows (decision 340): on a keyed `Dict` of `f64` it is refused at
> the write, naming the rows' type. A `bump` whose key or amount reads the var, and the increment
> written out — `counts = counts.insert(k, (counts.at(k) ?? 0) + n)`, which is not recognised as a
> `bump` — are the recompose refusal, as any row computed from the var's own rows is:
