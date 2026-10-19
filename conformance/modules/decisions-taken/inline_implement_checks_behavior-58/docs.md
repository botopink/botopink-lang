# Decision 58 — The inline `implement <Behavior> { }` check is `01-checker`'s row

The example declares a behavior, `Labelled`, with one required member, `label`, and two types that promise it with the inline clause written after their fields. `Euro(cents: i32) implement Labelled { … }` declares `label` in its body, so it keeps the promise and `Euro(cents: 250).label()` prints `EUR 250`. `Money(cents: i32) implement Labelled {}` makes the same promise with an empty body. The inline clause is checked exactly as a separate `implement Labelled for Money { … }` block would be: every member the behavior requires must be there. `Money` has no `label`, so the program is refused at `Money`'s declaration, the message naming the missing member, before any backend sees it. Nothing prints.

Cells in this repository that bear on it: `modules/implement/cases/implement_clause_for` (the separate block), `modules/decisions-taken/defer_runs_at_block_end-539/cases/ambient_behavior_implement_missing_method` and `modules/decisions-taken/negative_index_counts_from_end-139/cases/ambient_index_implement_missing_method` (a missing member under the separate block).

[draft/main.bp](draft/main.bp)
