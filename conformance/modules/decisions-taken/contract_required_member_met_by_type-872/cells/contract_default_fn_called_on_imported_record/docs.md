# contract_default_fn_called_on_imported_record

Decision 799 (1), 872: a contract's `default fn` is a member of the record that an extension block implements it
for, also when the block is written in a module other than the record's. `Tag` is the first module's, `TagShout`
the second's; `shout` is called on `Tag` from the block's module and from a third that activates the block
(`TagShout*`). The program runs.
