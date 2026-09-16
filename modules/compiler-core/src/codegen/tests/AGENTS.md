# compiler-core/src/codegen/tests

> Path: `modules/compiler-core/src/codegen/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Codegen tests, split by feature (`values.zig` etc. for codegen, `wat.zig` for the
WAT backend, `externals.zig` for `#[@External.<Target>(…)]` FFI declarations,
`comptime_module.zig` for `erlang.emitComptimeModule`). Aggregated by the
sibling barrel `../tests.zig` for `test_root.zig`; shared harness
(`assertJs`/`assertJsError`/`configs`) lives in `helpers.zig`.
For multi-module assertions without a snapshot, `assertConsumerJs(modules, present, absent)`
generates every module (last = consumer `main`) and checks the consumer's JS
contains/omits given substrings — used by the disk-lib namespace test in
`features.zig` (`import {Lib} from "Lib"` → `const Lib = require(...)`).
Golden outputs live in `modules/compiler-core/snapshots/codegen/<target>/<slug>.snap.md` (`commonJS`, `erlang`, `beam`, `wasm`), comptime validation errors in `codegen/errors/<target>/`.

`assertJsExpecting`, `assertJsError` and `assertJsTestMode` wrap their snapshot calls in `utils/snap.zig` `traceEnter(loc)`/`traceLeave`, so `BOTOPINK_SNAP_TRACE=<file>` records the test `file:line` for every codegen snapshot. A new helper that writes a snapshot must do the same, or `scripts/snap_audit.sh --mode=review` cannot attribute it.

## Pass/fail contract (spec 06, H3/H9/H10)

- `assertJs` / `assertJsSingle` **compare every backend before failing** and
  return the first error at the end, so one suite round writes every
  `.snap.md.new` (H10). Same for `assertJsError` and `assertJsTestMode`.
- A module that does not compile (parse error, type error, or comptime
  validation error) **fails the test** with `error.ModuleDidNotCompile`, and the
  snapshot records a `----- COMPILE DIAGNOSTIC -- <module>` section instead of
  an empty code section (H3/H9). Before this, 29 slugs × 4 backends were 0-byte
  snapshots that compared empty with empty and passed.
- `assertJsCompileError(alloc, @src(), src)` is the opt-in for a test whose
  point *is* that the program does not compile: it records the diagnostic and
  fails if the source ever starts compiling. Every call site carries a comment
  naming the missing feature and the spec that owns it (`DOCUMENTED SKIP —`).
- `assertJsError` stays the helper for comptime validation errors that have a
  dedicated `codegen/errors/<target>/` snapshot.

When adding a test file here, register it in `../tests.zig` or it will not run.
