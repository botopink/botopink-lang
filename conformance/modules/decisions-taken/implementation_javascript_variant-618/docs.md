# Decision 618 — `Implementation.Node` is renamed `JavaScript`: a source names the language the template is written in, not a runtime.

A host source names the language its template is written in. `mirror`'s JavaScript template is the variant
`.JavaScript(…)`, beside `.Erlang(…)`; the same source once spelled `.Node(…)` named a runtime, and `count` still writes
it: `Node` is no variant of `Implementation` any more, so the annotation is refused at `.Node`, and the program does not
run. With `.JavaScript` in its place it would print `cba` and `3`.

Cells that also bear on it: `modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_host`, `modules/behavior/cases/behavior_from_host_declare`.

[draft/main.bp](draft/main.bp)
