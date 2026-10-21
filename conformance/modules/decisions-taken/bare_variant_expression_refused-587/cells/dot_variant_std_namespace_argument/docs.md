# dot_variant_std_namespace_argument

A variant written with the leading dot, passed to a function of a std module reached through its namespace
(`unicode.normalize(s, .NFC)`, `process.onSignal(.Term, h)`), is resolved by the declared type of the parameter it is
passed to, as through a program module's namespace (`phase.describe(.Slow)`) or a leaf import.
