# template_val_value_not_comptime

Its `value` is the declaration's value at build only for a `val` whose initializer is `comptime` (decision 356): the value the program computed while it compiled, lifted into the template's module as a literal. A body that reads `value` is refused at an expansion whose answer holds any other entry (`typeinfo-all-template-value`).

A template body's read of an entry's `value` is refused when the entry is no `val` with a `comptime` initializer (`typeinfo-all-template-value`, decision 356): `#[theme] pub val brand = "violet";` — refused at the expansion.
