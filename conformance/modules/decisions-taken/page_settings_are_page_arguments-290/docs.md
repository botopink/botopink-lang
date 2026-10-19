# Decision 290 — No segment configuration; a page's settings are `#[page]` arguments.

A page's settings are arguments of its decorator, typed, beside its route: `blogPost` writes `revalidate: clock.hours(1)` — a `?Duration` from std's `io.clock`, regenerating a prerendered page after an hour — and `dynamicParams: false`; `about` writes only its route and takes the defaults, no revalidation and `dynamicParams: true`. `#[page]` records them as `PageSettings` meta, and the program prints `blog/[slug], revalidate 3600000ms, dynamicParams false` and `about, revalidate never, dynamicParams true`. There is no segment configuration besides: no registered config per route, no inheritance from a layout, and nothing — no `dynamic`, no `fetchCache` — that forces a page's stage, which is read from the hooks it reaches.

Cells in this repository that also bear on it: `modules/decisions-taken/compiler_annotation_labelled_arguments-305/cases/annotation_label_equals_decorator`.

[draft/main.bp](draft/main.bp) · [draft/comptime/pages.bp](draft/comptime/pages.bp)
