# compiler-core/src/codegen/tests

> Path: `modules/compiler-core/src/codegen/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md) (owns the per-file breakdown)

Codegen tests, split by feature (`js_*` for CommonJS, `wat.zig` for the WAT
backend, `externals.zig` for `@[external(…)]` FFI declarations). Aggregated by the sibling barrel `../tests.zig` for `test_root.zig`;
shared harness (`assertJs`/`assertJsError`/`configs`) lives in `helpers.zig`.
For multi-module assertions without a snapshot, `assertConsumerJs(modules, present, absent)`
generates every module (last = consumer `main`) and checks the consumer's JS
contains/omits given substrings — used by the disk-lib namespace test in
`js_features.zig` (`import {Lib} from "Lib"` → `const Lib = require(...)`).
Golden outputs live in `modules/compiler-core/snapshots/codegen/`.

When adding a test file here, register it in `../tests.zig` or it will not run.
