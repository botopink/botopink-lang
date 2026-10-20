# primitive_contract_dissolved

Decision 641: `String`, `Bool`, `BigInt`, `Bytes` and `Array` dissolved into their types, so
`String.fromCodepoint(65)` names nothing and is refused as an unknown name. It used to print `A`.
