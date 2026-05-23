# compiler-core/src/comptime — type inference, comptime & transform

> Path: `modules/compiler-core/src/comptime/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Examples: [`./examples.md`](examples.md)

This directory owns the most semantically rich stage of the compiler:
Hindley-Milner inference, comptime evaluation, and the AST transform pass
that specializes comptime calls. The target-agnostic façade is at
[`../comptime.zig`](../comptime.zig).

## Tree

```text
comptime/
├── types.zig          ← core Type union(enum)
├── env.zig            ← Env (binding name → *Type) + builtins/stdlib loading
├── infer.zig          ← `inferProgramTyped` (1672 lines) — HM walk
├── unify.zig          ← type-variable unification + occurs check
├── error.zig          ← TypeError struct (range + hint + comptime validation)
├── eval.zig           ← evaluation driver (delegates to runtime/{node,erlang}.zig)
├── render.zig         ← comptime value → target literal
├── specialize.zig     ← `SpecializedFn`, `SpecCache`, `specialize()` — body rewriting
├── transform.zig      ← `Aggregator` — drives the full transform pass
├── snapshot.zig       ← comptime snapshot helpers
├── tests.zig          ← `assertTypes`, `assertTypeErrorSnap`, …
└── runtime/           ← Node.js + Erlang eval backends
```

## Façade re-exports (`../comptime.zig`)

| Export | Use |
|---|---|
| `analyzeModule(…)` | lex / parse / validate comptime purity / infer |
| `evaluateComptime(…)` | run eval script via runtime, parse JSON output |
| `transform.transform(…)` | full AST rewrite pass |
| `ComptimeSession` | owns shared arena + per-module `ComptimeOutput` |

## Type system at a glance

`types.zig` defines a single `Type = union(enum) { … }`:

- Primitive: `i32`, `i64`, `u32`, `u64`, `f32`, `f64`, `bool`, `string`,
  `void`, `never`.
- Composite: `array`, `tuple`, `record`, `enum_`, `interface`, `errorUnion`.
- Polymorphic: `var_` (type variable), `forall` (generalised scheme),
  `function`.

Inference is **Hindley-Milner with let-polymorphism**:

1. `infer.zig` walks the AST, generating fresh type variables and unification
   constraints as it goes.
2. `unify.zig` solves them in place (with the occurs check) so the AST is
   annotated with concrete types at exit.
3. Errors are reported as `TypeError` (see `error.zig`) carrying a source
   range, a primary message, and an optional hint.

## Transform pass — the heart of comptime

```text
typed AST ──► Aggregator ──► transformed AST ──► codegen
```

`Aggregator` orchestrates five steps in order:

| # | Step | What happens |
|---|---|---|
| 1 | **Scan** | Walk decls + bodies; for each call to a fn with comptime params, run `specialize()` → `SpecializedFn` |
| 2 | **Rewrite** | `scale(2, base)` → `scale_$0(base)` (mangled name; comptime arg dropped from the call site) |
| 3 | **Inline** | `val x = comptime expr` → `val x = <evaluated_literal>` (via `render.zig`) |
| 4 | **Filter** | Drop original `FnDecl`s where **all** calls were specialized (the original is dead) |
| 5 | **Inject** | Push the new specialized `FnDecl`s into `program.decls` |

`Aggregator` maintains call counts so step 4 can decide whether a function
is fully specialised:

| Method | Role |
|---|---|
| `trackCall(fn_name)` | Count one observed call to a fn with comptime params |
| `trackSpecialization(fn_name)` | Count one call rewritten to a mangled name |
| `isFullySpecialized(fn_name)` | True if every observed call was rewritten — original is safe to drop |

After step 5 the AST contains only "plain" decls and calls. Codegen emitters
see no comptime — see [`../codegen/docs.md`](../codegen/docs.md).

## Why split inference, specialize, transform?

| File | Concern |
|---|---|
| `infer.zig` | Types only. Does not mutate AST shape. |
| `specialize.zig` | Pure AST → AST rewrite of a single call site. Does not consult call counts. |
| `transform.zig` | Coordinates the whole pass. Consults call counts. Decides what to keep, mangle, inline, drop. |

This layering keeps each file small enough to reason about. `infer.zig` is
the largest (~1700 lines) but does one thing.

## Evaluation flow

```text
analyzeModule(src)            → typed AST
  └─ comptime_exprs collected
eval.zig → runtime/<backend>  → executes generated script, returns JSON
render.zig                    → JSON value → target literal in the AST
```

The runtime backends (`runtime/node.zig`, `runtime/erlang.zig`) are
intentionally simple: write a script, exec it, parse JSON. See
[`runtime/docs.md`](runtime/docs.md).

## Testing helpers

```zig
try assertTypes(alloc, source, &.{ .{ "x", "i32" }, .{ "f", "fn(i32) i32" } });
try assertTypeErrorSnap(alloc, @src(), source);
```

`assertTypes` checks selected bindings have inferred to expected schemes.
`assertTypeErrorSnap` snapshots the rendered diagnostic.

Step-by-step walk-throughs and an `Aggregator` trace on a tiny example:
[`./examples.md`](examples.md).

## See also

- External eval backends → [`runtime/docs.md`](runtime/docs.md).
- Codegen sees the post-transform AST → [`../codegen/docs.md`](../codegen/docs.md).
- AST node catalogue → [`../ast.zig`](../ast.zig).
