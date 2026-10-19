# Decision 424 — A generic record or an imported alias is not a derived type's source.

The example derives two types with `Type.pick`. `Town` is a local alias of the record `City`, so it is that record: `Type.pick(Town, .name)` builds `TownName`, and `TownName(name: "Porto").name` would print `Porto`. `Box<T>` is a generic record, so `Type.pick(Box, .item)` has no fields to copy until `T` is known. It is refused at that argument, `derived-type-source-not-record`. An alias imported from another module is refused the same way. The program never builds.

Cells in this repository that bear on it: `modules/derived_type_not_record`, `modules/derived_type_primitive`, `modules/derived_type_imported`.

[draft/main.bp](draft/main.bp)
