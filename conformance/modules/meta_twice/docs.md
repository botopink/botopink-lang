# meta_twice

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298)):

> A type is recorded once per declaration with `setMeta` — a second value of it,
> or one added with `addMeta` beside it, is `decorator-meta-twice` at the
> annotation that recorded it —, and `meta(T)` over several values is
> `typeinfo-meta-several` (read them with `metaAll(T)`). Meta describes a
> top-level declaration (`decorator-meta-on-member` from a field's or a method's
> decorator).
