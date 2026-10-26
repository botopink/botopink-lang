# Decision 630 — The records stay in `compiler.bp`, the utilities in `types.bp`: `compiler.Field<T>` and `compiler.Info<T>` are the types `Compiler` names, and `Type` — with `partial`, `pick`, `omit`, `merge`, `required` as statics written in botopink (628) — is `types.bp`, which imports `compiler`.

The two records the compiler's reflection answers are named through `compiler`: `import {compiler.Field, compiler.Info} from "std";` brings `Field<T>` and `Info<T>` from `compiler.bp`, where `Compiler` declares `fields` and `typeInfo` over them. `Type`, with `pick` and the other utilities written in botopink, is imported from `types`, the module that imports `compiler` — the dependency runs one way only. `compiler.fields(Livro)`, read at build under `comptime`, is a `Field<Livro>[]` that crosses into the run time as its constructor over the owner and the name: the program prints the names `titulo,paginas,autor` and the second field itself, `Field(Livro, "paginas")`. `compiler.typeInfo(Livro).name` prints `Livro`. `Type.pick(Livro, .titulo, .autor)` builds `Resumo`, and the program prints `Dom Casmurro Machado`.

Cells in this repository that also bear on it: `modules/decisions-taken/derived_type_static_methods-307/cases/derived_type_functions`, `modules/decisions-taken/derived_type_static_methods-307/cells/derived_type_imported`.

[draft/main.bp](draft/main.bp)
