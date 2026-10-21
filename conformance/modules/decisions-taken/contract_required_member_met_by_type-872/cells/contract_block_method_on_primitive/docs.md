# contract_block_method_on_primitive

Decisions 799, 872: the method an extension block defines for a primitive (`label` of `StringShout` for `string`) is called on a primitive receiver from the block's module and from an importer that
activates the block, and the contract's `default fn` (`shout`) calls it and returns the string it builds. The
program runs on every target.
