# compiler-core/src/comptime/tests

> Path: `modules/compiler-core/src/comptime/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Inference/comptime tests, split by feature. Aggregated by the sibling barrel
`../tests.zig` for `test_root.zig`; golden snapshots live in
`modules/compiler-core/snapshots/comptime/`.

When adding a test file here, register it in `../tests.zig` or it will not run.

| File | Covers |
|---|---|
| `helpers.zig` | Shared harness (no tests): `assertComptimeAst`, `assertComptimeAstSingle`, `assertComptimeCompileError`, `assertTypeErrorSnap`, `assertInfersOk`, `renderTypeError`. |
| `infer_exprs.zig` | Literal / binary / case / control-flow inference. |
| `infer_decls.zig` | fn / record / interface / implement / test-block inference. |
| `infer_generics.zig` | Type meta-kind + generic inference (regression guards). |
| `infer_errors.zig` | Inference type errors (`infer error: …`). |
| `types.zig` | Types / type unification. |
| `variants.zig` | Variants, record update, patterns, `@print`, AST probes. |
| `narrowing.zig` | Null-check / case-variant / type-guard narrowing. |
| `exhaustiveness.zig` | `case` exhaustiveness + reachability errors. |
| `effects.zig` | throw / context / `@Result` effect checking. |
| `effect_result.zig` | `#[@result]` contract (R-codes). |
| `effect_future.zig` | `#[@future]` contract (RF-codes). |
| `effect_generator.zig` | `#[@generator]` contract (`yield`, labels). |
| `generic_defaults.zig` | Default generic parameters (RG-codes). |
| `templates.zig` | `@Expr` capture, scope snapshot, methods, expansion. |
| `decorators.zig` | Decorator recognition + argument validation. |
| `decorator_invocation.zig` | Decorator body invocation + `fail` diagnostics. |
| `decorator_regression.zig` | Decorator bodies with loops / conditionals / string concat / `@emit` / accumulator fold fusion. Each lowering has a rejecting fixture compared on the whole message and an accepting fixture that asserts the lowered Erlang (`OkData.comptime_traces`: `lists:foreach(`, `'__bp_len'(`, `'__bp_add'(`, `lists:foldl(`; the `@emit` reply exactly), so every row of `specs/1.0.4-beta/05-cli-residuals/mutation-matrix.md` (M1–M10) and a fold fusion that discards its accumulator reds a test. Run alone: `zig build test -Dtest-filter="decorator regression"`. |
| `builtins_typeinfo.zig` | `@typeInfo` / `@TypeOf` / `@makeRecord` / `@RecordKeys` / `@Field` inference. |
| `std_target_gating.zig` | `from "std"` imports rejected on targets without `@external` coverage. |
| `eval_pipeline.zig` | Source → infer → `evaluateComptime` for comptime vals. |

## Pass/fail contract (spec 06, H3/H9)

- `assertComptimeAst` / `assertComptimeAstSingle` **fail** with
  `error.ModuleDidNotCompile` when a module ends in `.parseError`,
  `.typeError` or `.validationError`, and the snapshot records a
  `----- COMPILE DIAGNOSTIC -- <module>` section instead of stopping after
  `SOURCE CODE`. Before this, 39 slugs were source-only snapshots that compared
  source with source and passed.
- `assertComptimeCompileError(alloc, @src(), src)` is the opt-in for a test
  whose point *is* that the program does not compile: it records the diagnostic
  and fails if the source ever starts compiling. Every call site carries a
  comment naming the missing feature and the spec that owns it
  (`DOCUMENTED SKIP —`).
- `renderTypeError` (the `comptime/*/errors/` snapshots) is a thin wrapper over
  `comptime/snapshot.zig` `renderTypeErrorBody`, which the diagnostic sections
  reuse — both texts stay in sync by construction.
- `BOTOPINK_SNAP_CREATE=1` is required to record a *missing* snapshot
  (`utils/snap.zig`).
- `assertComptimeAstExpecting` and `assertTypeErrorSnap` (and the one direct
  `checkText` in `templates.zig`) wrap their snapshot calls in
  `snapMod.traceEnter(loc)`/`traceLeave`, so `BOTOPINK_SNAP_TRACE=<file>` records
  the test `file:line`. A new snapshot-writing helper must do the same.
