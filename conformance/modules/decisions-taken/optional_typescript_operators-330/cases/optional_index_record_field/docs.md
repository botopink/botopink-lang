# optional_index_record_field

The reference text this cell shows (from `conformance/docs.md`, § Optionals):

> A `?.` makes the rest of its chain conditional: at the first absent link the whole
> chain is absent, and a member or a method after the link runs only on a present
> value — `xs?.[i]` over an optional array of records is the record, and a field
> read off it, by `?.` or by `!`, is the record's own.
