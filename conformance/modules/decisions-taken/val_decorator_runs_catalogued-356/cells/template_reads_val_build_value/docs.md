# template_reads_val_build_value

Its `value` is the declaration's value at build only for a `val` whose initializer is `comptime` (decision 356): the value the program computed while it compiled, lifted into the template's module as a literal. A body that reads `value` is refused at an expansion whose answer holds any other entry (`typeinfo-all-template-value`).

In a template body (decision 353) a catalogued `val`'s `value` is its build value, lifted into the template's module as a literal when its initializer is `comptime` (decision 356): `#[theme] pub val brand = comptime "violet".toUpperCase();` — `page: VIOLET`.
