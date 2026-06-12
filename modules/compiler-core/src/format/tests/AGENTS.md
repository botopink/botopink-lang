# compiler-core/src/format/tests

> Path: `modules/compiler-core/src/format/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Formatter tests, split by feature (`idempotent.zig` checks `fmt(fmt(x)) == fmt(x)`).
Aggregated by the sibling barrel `../tests.zig` for `test_root.zig`; shared
harness lives in `helpers.zig`.

When adding a test file here, register it in `../tests.zig` or it will not run.
