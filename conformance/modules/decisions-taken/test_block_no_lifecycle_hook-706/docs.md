# Decision 706 — No test lifecycle hook: nothing implicit runs around a `test` block; a test body calls its reset helper.

Nothing implicit runs around a `test` block: there is no `beforeEach`, no `afterAll`, no hook of any kind. The module
keeps a counter in a module `var`, and each test body that needs it fresh calls `reset()` itself, as its first
statement, so each test reads as what it does. Run as a program, `main` shows the same helper at work: `record()`
counts `1` and `2`, `reset()` puts the counter back, and the next `record()` is `1` again.

[draft/main.bp](draft/main.bp)
