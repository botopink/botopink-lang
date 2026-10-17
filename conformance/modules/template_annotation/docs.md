# template_annotation

The reference text this cell shows (from `conformance/docs.md`, § Template annotations (decision 311)):

> **A method's typed meta, read by its owner's decorator** (question `s29-b`).
> A method's decorators — a template annotation and a `#[d(…)]` alike — run
> before its owner's, and the typed meta they record (`decl.setMeta(v)`,
> `decl.addMeta(v)`) is read by the owner's decorator on a `decl.methods` entry:
> `m.meta(T)` is a `?T`, `m.metaAll(T)` a `T[]`, `T` the record written by its
> declared name. A field's decorator still records no meta
> (`decorator-meta-on-member`).
