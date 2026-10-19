# Decision 362 — `05-jhonstart/26` rewrites the native builders into 351's props form, in place, and the hand-written callers with them — one builder per tag, never two.

A native tag has one builder, and its first parameter is the element's props record — the rule of a component. `AnchorProps` is built by layering two records with `Type.merge`: the anchor's own attributes (`href`, a typed `target` enum) and the global ones every element shares (`id`, `class`, and the content in `children`). `a(props: AnchorProps)` is the whole of `<a>`'s builder: there is no second form taking content and attributes apart. The program prints `<a href="/">home</a>` and `<a href="/docs" target="_blank" class="nav">docs</a>`. A misspelt attribute — `hreff` — is no field of `AnchorProps` and is refused where it is written, which in markup is the attribute.

Cells in this repository that also bear on it: `modules/decisions-taken/derived_type_static_methods-307/cases/derived_type_functions`, `modules/decisions-taken/component_props_plain_or_rest-529/cases/record_param`.

[draft/main.bp](draft/main.bp) · [draft/elements.bp](draft/elements.bp)
