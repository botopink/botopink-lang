# Decision 420 — A generic meta record is not read through a catalogue entry.

A meta record may be generic, and it is read through the type that carries it. `#[rule]`, in
[draft/comptime/rules.bp](draft/comptime/rules.bp), appends a `Rule<T>` to the annotated type, `T` the type itself, each record
holding the rule written in the annotation — a `syntax` argument, kept as code and resolved in `Order`'s module.
`failing` reads them with `compiler.typeInfo(Order).metaAll(Rule)` under `comptime`, and the read answers `Rule<Order>[]` — the type argument known because the reflected type is named. A
generic record has no reading through a catalogue entry, where the type argument would be lost; the catalogue itself is
gone (665), each declaration's meta read through its own type. `main` prints `[]` and `["small"]`.

Cells that also bear on it: `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_catalogue_generic`, `modules/decisions-taken/decorator_expr_typed_channels-370/cases/meta_expr_field`.

[draft/main.bp](draft/main.bp)
