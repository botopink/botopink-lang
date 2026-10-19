# meta_typed_records

The reference text this cell shows (from `conformance/docs.md`, § Typed meta (decision 298)):

> A decorator's meta is a typed value keyed by its record type, never by the
> decorator's name: `decl.setMeta(Entity(table: table.value))` records one
> `Entity` on the declaration, `decl.addMeta(Index(column: c.value))` one more
> `Index` each time. A reader names the type — `@typeInfo(City).meta(Entity)` is
> an `?Entity` (`null` when nothing recorded one), `@typeInfo(City).metaAll(Index)`
> an `Index[]` —, so a renamed decorator changes no reader, two decorators may
> write one type, and who may read is who sees the type. The values are built at
> build time and written back as their constructors where they are read: each
> field is a string, an integer, a float, a `bool`, a variant of an enum without
> payloads, an array or an optional of those (`decorator-meta-field-type`), and
> the value is the record's constructor written at the call
> (`decorator-meta-not-record`), in the decorator's own body.
