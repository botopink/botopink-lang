# compiler-core/src/comptime/tests

> Path: `modules/compiler-core/src/comptime/tests/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Inference/comptime tests, split by feature. Aggregated by the sibling barrel
`../tests.zig` for `test_root.zig`; golden snapshots live in
`modules/compiler-core/snapshots/comptime/`.

When adding a test file here, register it in `../tests.zig` or it will not run.

| File | Covers |
|---|---|
| `helpers.zig` | Shared harness (no tests): `assertComptimeAst`, `assertComptimeAstSingle`, `assertTypeErrorSnap`, `assertInfersOk`. |
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
| `decorator_regression.zig` | Decorator bodies with loops / conditionals / string concat. |
| `builtins_typeinfo.zig` | `@typeInfo` / `@TypeOf` / `@makeRecord` / `@RecordKeys` / `@Field` inference. |
| `std_target_gating.zig` | `from "std"` imports rejected on targets without `@external` coverage. |
| `eval_pipeline.zig` | Source → infer → `evaluateComptime` for comptime vals. |
