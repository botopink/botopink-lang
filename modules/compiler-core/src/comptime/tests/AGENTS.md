# compiler-core/src/comptime/tests

> Path: `modules/compiler-core/src/comptime/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Inference/comptime tests, split by feature. Aggregated by the sibling barrel
`../tests.zig` for `test_root.zig`; shared harness (`assertComptimeAst`,
`assertTypeErrorSnap`, …) lives in `helpers.zig`. Golden snapshots live in
`modules/compiler-core/snapshots/comptime/`.

When adding a test file here, register it in `../tests.zig` or it will not run.
