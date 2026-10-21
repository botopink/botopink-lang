# primitive_type_redeclared_refused

Decision 639 (a): a module declaring a type named like a literal's type — `i32`, `i64`, `u32`, `u64`, `f32`, `f64`,
`bool`, `string`, `bigint` — is refused at the name, `primitive-type-redeclared`. A literal is typed by the checker, not
by a name lookup, so a shadowing `type i32(…)` would make `val x: i32 = 1` a mismatch between two `i32`s. Every other
prelude name shadows as 606 (1) says: the module's own `Result` is legal. `type i32(value: i64)` used to be accepted on
three targets and abort on wasm.
