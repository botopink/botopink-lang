# primitive_static_on_type

Decision 641: a primitive type holds its own statics, called through its lowercase name —
`string.fromCodepoint(65)`, `array.range(0, 3)`, `array.repeat("ab", 2)`, `bytes.fromUtf8("hi")`,
`bigint.of(5)` — on every target. Each used to be written through a capitalised behavior
(`String.fromCodepoint`, `Array.range`, `Bytes.fromUtf8`) that the type now replaces.
