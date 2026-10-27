# Decision 705 — Outside markup, expression-level work is a call (`traced(compute())`); a tag's annotation is the one expression-position decorator (278, 302, 369), and `val x = #[deco] 1;` stays refused.

The example wants to trace one computation. The form that is accepted is a call: `traced(compute())` hands the value to `traced`, which prints `traced` and answers it. The program also writes `val y = #[traced] 2;`, an annotation on an expression outside markup, which is refused at the annotation. The one expression-position decorator is a tag's annotation inside markup, where the tag and the declaration's decorator are one thing. Everywhere else expression-level work is a call. The program never builds; without its last binding it would print `traced` and `42`.

Cells in this repository that bear on it: `modules/decisions-taken/tag_annotation_is_decorator-302/cases/tag_annotation_meta_twice`, `modules/decisions-taken/tag_annotation_is_decorator-302/cases/tag_decl_meta`.

[draft/main.bp](draft/main.bp)
