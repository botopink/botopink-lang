# compiler-core/src/comptime/tests

> Path: `modules/compiler-core/src/comptime/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Inference/comptime tests, split by feature. Aggregated by the sibling barrel
`../tests.zig` for `test_root.zig`; golden snapshots live in
`modules/compiler-core/snapshots/comptime/`.

## Snapshot layout — one file per test

| Directory | Written by | Holds |
|---|---|---|
| `comptime/ast/` | `assertComptimeAst` (`../snapshot.zig`), through the `helpers.zig` wrapper | the typed-AST snapshot of a test that compiles (or records its `COMPILE DIAGNOSTIC`) |
| `comptime/errors/` | `assertTypeErrorSnap` (`helpers.zig`) | the rendered type error of a test that must not infer |
| `comptime/templates/` | `checkText` in `templates.zig` | the `@Expr` capture/expansion fixtures |

Until 1.0.5-beta front 06 every AST snapshot was written four times
(`comptime/{node,erlang,wasm,beam}/<slug>`) and every type error twice
(`comptime/{node,erlang}/errors/<slug>`). The copies were always byte-identical:
the four-runtime architecture collapsed in v0.beta.21, when one comptime runtime
replaced the per-backend runtimes (the WAT runtime and its host among them),
and the per-runtime loop only changed `RunResult.script`, which these snapshots
do not include. The layout outlived it to avoid stale-file churn, at the cost of
four files per review row. 1079 files became 338, with no change to what the
compiler emits.

**Reading the older reports.** The 1.0.1-beta audit and the 1.0.4-beta front
documents cite the old paths — `SN/<slug>` and `snapshots/comptime/node/<slug>`
are today's `snapshots/comptime/ast/<slug>`, and
`snapshots/comptime/{node,erlang}/errors/<slug>` is today's
`snapshots/comptime/errors/<slug>`. Those reports are the audit record and are
not rewritten; this table is the mapping.

When adding a test file here, register it in `../tests.zig` or it will not run.

| File | Covers |
|---|---|
| `helpers.zig` | Shared harness (no tests): `assertComptimeAst`, `assertComptimeAstSingle`, `assertComptimeCompileError`, `assertTypeErrorSnap`, `assertInfersOk`, `renderTypeError`. |
| `infer_exprs.zig` | Literal / binary / case / control-flow inference; `@src()` typing as `SourceLocation` (`src_types_as_sourcelocation`). |
| `infer_decls.zig` | fn / record / interface / implement / test-block inference. |
| `infer_generics.zig` | Type meta-kind + generic inference (regression guards). |
| `infer_errors.zig` | Inference type errors (`infer error: …`), including `src-takes-no-arguments` and `unknown-builtin` (with and without a near name). The decision 38 / front 17 rows (`val` assignment, `@BeamMemory` validation) assert the message by content through `typeErrorMessage` — no cell under `snapshots/comptime/errors/`. |
| `types.zig` | Types / type unification. |
| `variants.zig` | Variants, record update, patterns, `@print`, AST probes. |
| `narrowing.zig` | Null-check / case-variant / type-guard narrowing. |
| `exhaustiveness.zig` | `case` exhaustiveness + reachability errors. |
| `effects.zig` | throw / context / `@Result` effect checking. The `context:` cells carry `#[@context]` on every body that writes `use` (decision 88 of 1.0.10-beta); `use without #[@context] on a -> Element body` pins the `use-without-context-effect` diagnostic and `#[@context] fn -> Element (owner type) passes` the component form. Decisions 89 + 90: `#[@future] fn -> @Future<Element> activates without #[@context]` pins the wrapper-effect dispensation, and the three refusals it must not switch off are `#[@future] fn -> @Future<i32> still refuses use` (no owner after the unwrap), `#[@context] on a return type that owns no context` (`effect-wrapper-mismatch`) and `#[@future] fn -> @Future<Element> owner mismatch` (`context-anchor-violation`). Front 19 step 3: `use tuple destructure binds element types` pins that `val #(shown, push) = use optimistic(…)` binds `R`'s elements (its `error:` sibling reds on `push("x")`), and `use tuple destructure arity mismatch` / `… whose R is not a tuple` pin `use-tuple-arity`. |
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
- `renderTypeError` (the `comptime/errors/` snapshots) is a thin wrapper over
  `comptime/snapshot.zig` `renderTypeErrorBody`, which the diagnostic sections
  reuse — both texts stay in sync by construction.
- `BOTOPINK_SNAP_CREATE=1` is required to record a *missing* snapshot
  (`utils/snap.zig`).
- `assertComptimeAstExpecting` and `assertTypeErrorSnap` (and the one direct
  `checkText` in `templates.zig`) wrap their snapshot calls in
  `snapMod.traceEnter(loc)`/`traceLeave`, so `BOTOPINK_SNAP_TRACE=<file>` records
  the test `file:line`. A new snapshot-writing helper must do the same.
