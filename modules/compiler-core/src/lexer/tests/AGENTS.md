# compiler-core/src/lexer/tests

> Path: `modules/compiler-core/src/lexer/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Lexer tests, split by feature. Meant to be aggregated by the sibling barrel
`../tests.zig` for `test_root.zig`, but that barrel currently imports none of
these files, so they do not run. `helpers.zig` is an empty placeholder.

When adding a test file here, register it in `../tests.zig` or it will not run.
