# Decision 961 — std's context helpers the component lowering calls — `stamp`, `stampPlain`, `stampKeyed`, `memoIn`, `allIn`, `countNew`, `countEnd`, and the older `enter`, `provideIn`, `find` — are private to `context.bp`; the lowering reaches them through 830's call mark alone; amends 817 (1), 814 (2), 830.

[cells/context_helpers_private/src/main.bp](cells/context_helpers_private/src/main.bp)
[cells/stamp_keyed_call_refused/src/main.bp](cells/stamp_keyed_call_refused/src/main.bp)
[cells/helpers_private_component_unchanged/src/main.bp](cells/helpers_private_component_unchanged/src/main.bp)
