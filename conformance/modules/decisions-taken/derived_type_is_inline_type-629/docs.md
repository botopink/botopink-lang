# Decision 629 — A derived type is an inline type named by its `val` — `pub val Patch = Type.partial(Pessoa);` is `pub val Patch = type(nome: ?string, idade: ?i32, email: ?string);` — built by `compiler.buildTypeInline(fields) -> anytype`; there is no lineage, and a spread is typed by structure.

[cases/record_spread_derived_partial/src/main.bp](cases/record_spread_derived_partial/src/main.bp)
[cases/record_spread_partial/src/main.bp](cases/record_spread_partial/src/main.bp)
[cases/record_spread_required/src/main.bp](cases/record_spread_required/src/main.bp)
