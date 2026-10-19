# Decision 624 — (d): `compiler.bp` incorporates `types.bp` whole — `Type`, with `Field<T>`, `Info<T>` and the five utilities (`partial`, `pick`, `omit`, `merge`, `required`), is declared inside `compiler.bp`, and `types.bp` goes.

The decision removed a cycle between `compiler.bp` and the module holding `Type`; as amended by decision 630, the records `Compiler` names are `compiler.bp`'s and `Type` stays in `types.bp`, which imports `compiler`. The program uses both sides. `#[fieldList]` reads `Pessoa`'s fields with `compiler.fields(decl)`, typed `compiler.Field<unknown>[]`, and each field's annotations, `DeclAnnotation`s — every type the reflection answers lives in the module that declares `Compiler`, so nothing depends on a module that depends back. It records `nome 1; idade 0`, which `main` reads through `compiler.typeInfo(Pessoa)` — itself a `compiler.Info<Pessoa>` — and prints. `Type.partial(Pessoa)` is written as before, imported from `types`: `Patch` is the inline type with every field optional, and the program prints `Ana 0`. One name per type, no alias.

Cells in this repository that also bear on it: `modules/derived_type_functions`, `modules/derived_type_declarations`.

[draft/main.bp](draft/main.bp) · [draft/comptime/fields.bp](draft/comptime/fields.bp)
