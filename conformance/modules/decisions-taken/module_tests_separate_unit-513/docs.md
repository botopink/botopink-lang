# Decision 513 — A module's tests are a unit of their own; its production unit is the same in `build`, `run` and `test`.

`geometry` has a private function, `area`, a public one that uses it, and a `test` block that calls `area` directly. Run as a program, it prints `3 x 4 = 12`; its compiled `geometry` unit is the same bytes whether it was built by `build`, `run` or `test`. Under `botopink test` of this package, the test block is compiled into a unit of its own beside the production unit — `'__test__@<package>@geometry'` on erlang, `__test__/geometry.js` on commonJS, linked into the one module only under `test` on wasm — and it reaches the private `area` through the reserved export the production unit always carries (`'__bp_priv__area'/1` on erlang and beam, a hidden export object on commonJS). A consumer of this package never gets its test units, and a test unit is never cached.

[draft/main.bp](draft/main.bp) · [draft/geometry.bp](draft/geometry.bp)
