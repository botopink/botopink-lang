# Decision 641 — (b) for the names, and no contract with one implementor: every primitive type is written lowercase — `i32`, `i64`, `u32`, `u64`, `f32`, `f64`, `bool`, `string`, `bigint`, `bytes`, `array<T>` — and a capitalised name is a contract shared by several types (`Number`, `Integer`, `Signed`, `Float`); `String`, `Bool`, `BigInt`, `Bytes` and `Array` dissolve into their types, which hold their methods and statics.

Every primitive type is written lowercase and holds its own statics, called through the type's name: `string.fromCodepoint(65)` answers `A`, `array.range(0, 3)` answers `[0, 1, 2]` (an `array<i32>`, spelt `i32[]`), `array.repeat("ab", 2)` joined answers `ab,ab`, `bytes.fromUtf8("hi").length()` answers `2` and `bigint.of(5) * bigint.of(7)` answers `35`, on every target. A capitalised name is never one of those types: it is a contract several types share (`Number`, `Integer`, `Signed`, `Float`). `String`, `Bool`, `BigInt`, `Bytes` and `Array` are no names at all: `String.fromCodepoint(65)` is refused as an unknown name, `unbound variable 'String'`.

Cells in this repository that also bear on it: `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/integer_conversions_exact`, `modules/primitive/cases/primitive_method_undeclared`, `modules/primitive/cases/primitive_type_name_taken`.

[cases/primitive_static_on_type/src/main.bp](cases/primitive_static_on_type/src/main.bp)
[cases/primitive_contract_dissolved/src/main.bp](cases/primitive_contract_dissolved/src/main.bp)
