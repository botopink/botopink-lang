# record_spread

The reference text this cell shows (from `conformance/docs.md`, § Spread):

> `Name(..src, field: value)` copies a record's fields into its constructor
> (decision 359): `..src` at the start of an argument, any number of them,
> mixed with labels. The arguments apply left to right, the later winning; a
> field no spread and no label supplies takes its default. The spread builds a
> new record — `src` is read, never changed — and `a...b` stays the inclusive
> range.
