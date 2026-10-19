# Decision 696 — A template function is an annotation only when its signature declares the annotated declaration as its second parameter (578 (1): `syntax q: string`, then `syntax decl: unknown`); called as `` f @`…` `` it is `template-annotation-only`, and a template without that parameter at `#[f @`…`]` is `template-annotation-without-decl`.

`sql` is a template whose signature takes the annotated declaration as its second parameter — `syntax q: string`, then `syntax decl: unknown` —, and that signature says which form it takes: an annotation. `#[sql @`…`]` on `users` is that form, recording the query text as typed meta. The last line of `main` calls the same template as an expression, `` sql @`select 1` ``, and the program is refused there with `template-annotation-only`: the function takes the annotated declaration, so it is written as an annotation, never called. The converse is refused too: a template without that second parameter written as `#[f @`…`]` is `template-annotation-without-decl`. The two uses are two functions.

Cells in this repository that also bear on it: `modules/template_annotation_called`, `modules/template_annotation_without_decl`, `modules/template_annotation`.

[draft/main.bp](draft/main.bp) · [draft/comptime/sql.bp](draft/comptime/sql.bp)
