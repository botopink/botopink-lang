# effect_type_removed_yield

The reference text this cell shows (from `conformance/docs.md`, § Migrating from the effect annotations):

> 1.0.10-beta replaced the effect annotations with the return type (decisions
> 118–128) and kept no compatibility window (decision 127): every old form below
> is a located compile error with a fix-it — `effect-annotation-removed` for an
> annotation (on a loop it suggests `iter` / `stream`), `effect-type-removed` for
> a wrapper name, `iterator-error-param-removed` for `Iter<T, E>`. There is
> no automatic rewriter: each error names the new spelling, from the table below.
