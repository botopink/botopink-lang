# contract_default_fn_called_on_target

Decision 799 (1), 872: a contract's `default fn` is a member of the type that an extension block implements it
for, wherever the block is visible. `shout` is called on a record (`Tag`) and on a primitive (`string`), from
the module of the `pub` blocks and from an importer that activates them (`TagShout*`, `StringShout*`). The
program runs.
