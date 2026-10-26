# contract_block_method_on_int

Decisions 799, 872: the method an extension block defines for a numeric primitive (`label` of `IntShout` for `i32`,
`label` of `TextShout` for `string` — two blocks writing one method name) is called on a numeric receiver, and the
contract's `default fn` (`shout`) calls it. The program runs on every target.
