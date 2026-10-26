# Decision 639 — (a): a module declaring a type named like a literal's type — `i32`, `i64`, `u32`, `u64`, `f32`, `f64`, `bool`, `string`, `bigint` — is refused at the name, `primitive-type-redeclared`; 606 (1)'s shadowing does not reach them.

The example declares two types named after prelude types. `type Result(ok: bool)` shadows the prelude's `Result` in this module, which is legal. `type i32(value: i64)` is refused at the name, `primitive-type-redeclared`. The literal `1` in `val x: i32 = 1` is typed `i32` by the checker and not by looking up a name, so a module-level `i32` would make that line a mismatch between two `i32`s. The literal types are exactly the ones that cannot be shadowed: `i32`, `i64`, `u32`, `u64`, `f32`, `f64`, `bool`, `string` and `bigint`.

Cells in this repository that also bear on it: `modules/primitive/refused/src/cases/primitive_type_name_taken`, `modules/primitive/refused/src/cases/primitive_type_name_taken_val`.

[cases/primitive_type_redeclared_refused/src/main.bp](cases/primitive_type_redeclared_refused/src/main.bp)
[cases/primitive_width_redeclared_refused/src/main.bp](cases/primitive_width_redeclared_refused/src/main.bp)
