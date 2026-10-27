# implement_signature_spellings_met

Decision 974 (1), (2): the signature check compares types, not spellings — `array<i32>` meets an alias
`Ints = i32[]`, `string[]` meets `array<string>`, `Box` meets `Self<U>` under `implement Mappable<i32>`,
and a `comptime` parameter meets a `comptime` one. The program runs.
