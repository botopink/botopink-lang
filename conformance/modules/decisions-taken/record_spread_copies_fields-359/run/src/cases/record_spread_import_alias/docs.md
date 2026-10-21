# record_spread_import_alias

The reference text this cell shows (from `conformance/docs.md`, § Spread):

> The source is any expression whose type is the record itself or a type derived
> from it by `Type.pick`, `Type.omit` or `Type.merge` — a call, a method call, a
> field path, another spread — evaluated once however many fields it supplies.
> The lineage holds across modules and through an import alias: a type derived in
> another module from an imported record, or from an imported derived type, is
> derived from that record.
