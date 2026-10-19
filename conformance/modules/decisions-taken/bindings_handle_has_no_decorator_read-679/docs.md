# Decision 679 — A handle `compiler.bindings(e)` answers has no read of the decorator that annotated it; a template body tells annotations apart by the meta they recorded, read by type (`compiler.meta<RawBody>(d)`, 302, 576 (11)).

The template `kinds`, declared in the build layer ([draft/comptime/marks.bp](draft/comptime/marks.bp)), tells two declarations apart by the meta they recorded, not by which decorator annotated them. `Users` carries `#[raw("trusted")]`, whose decorator records the typed meta `RawBody(reason: "trusted")`. `Orders` carries nothing. For each handle `compiler.bindings(q)` answers, the template reads `compiler.meta<RawBody>(d)`. It gets the record for `Users` and `null` for `Orders`, so the program prints `Users trusted, Orders plain`. The handle offers no read of "the decorator that annotated it". There is no `Decorator` type to compare, and where an annotation's decorator is the question, its `DeclAnnotation.decorator` handle is compared with `compiler.same`.

Cells in this repository that bear on it: `modules/decisions-taken/query_template_assembled_at_build-415/cases/template_lookup_meta`, `modules/decisions-taken/query_template_assembled_at_build-415/cases/template_bindings_decls`, `modules/decisions-taken/tag_annotation_is_decorator-302/cases/tag_annotation_reads_meta`.

[draft/main.bp](draft/main.bp)
