# template_annotation

The reference text this cell shows (from `conformance/docs.md`, § Template annotations (decision 311)):

> **A method's typed meta, read by its owner's decorator** (question `s29-b`).
> A method's decorators — a template annotation and a `#[d(…)]` alike — run
> before its owner's, and the typed meta they record (`compiler.setMeta(v)`,
> `compiler.addMeta(v)`) is read by the owner's decorator on a `compiler.methods(decl)` entry:
> `compiler.meta<T>(m)` is a `?T`, `compiler.metaAll<T>(m)` a `T[]`, `T` the record written by its
> declared name. A field's decorator still records no meta
> (`decorator-meta-on-member`).
