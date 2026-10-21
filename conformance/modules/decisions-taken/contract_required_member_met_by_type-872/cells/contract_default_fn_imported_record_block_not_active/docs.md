# contract_default_fn_imported_record_block_not_active

Decision 872: the `default fn` a block gives a record is visible where the block is — its own module and an
importer that activates it (`TagShout*`). `main.bp` imports `Tag` and `local` but not the block, so
`Tag(name: "b").shout()` is refused.
