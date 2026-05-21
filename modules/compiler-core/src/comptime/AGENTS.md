# compiler-core/src/comptime

> Path: `modules/compiler-core/src/comptime/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Hindley-Milner type inference, comptime evaluation, and the AST transform pass
that specializes comptime calls. The target-agnostic façade is at
`../comptime.zig`.

## Tree

```text
comptime/
├── AGENTS.md          ← you are here
├── types.zig          ← core Type union(enum)
├── env.zig            ← Env (binding name → *Type) + builtins/stdlib loading
├── infer.zig          ← `inferProgramTyped` — walks AST, returns []TypedBinding
├── unify.zig          ← type-variable unification
├── error.zig          ← structured TypeError with source locations + comptime validation
├── eval.zig           ← evaluation driver (delegates to runtime/{node,erlang}.zig)
├── render.zig         ← comptime value → target literal
├── specialize.zig     ← `SpecializedFn`, `SpecCache`, `specialize()` — body rewriting
├── transform.zig      ← `Aggregator` — drives the full transform pass
├── snapshot.zig       ← comptime snapshot helpers
├── tests.zig          ← `assertTypes`, `assertTypeErrorSnap`, …
└── runtime/           ← Node.js + Erlang eval backends — see runtime/AGENTS.md
```

## Files

| File | Role |
|---|---|
| `types.zig` | All type representations as `union(enum)`. |
| `env.zig` | Type environment — pushes/pops scopes, loads builtins + stdlib. |
| `infer.zig` | Main HM inference: `inferProgramTyped(...) → []TypedBinding`. |
| `unify.zig` | Unification with substitution + occurs check. |
| `error.zig` | Structured type errors with source ranges and hints. |
| `eval.zig` | Builds eval scripts, calls runtime, parses JSON results. |
| `render.zig` | Converts an evaluated comptime value into a target literal. |
| `specialize.zig` | Pure AST specialization — unroll loops, fold static if/case. |
| `transform.zig` | `Aggregator` — drives specialize + rewrite + inline + dead-code. |
| `snapshot.zig` | Snapshot helpers. |
| `tests.zig` | Test entry points (`assertTypes`, `assertTypeErrorSnap`). |

## Façade (`../comptime.zig`)

Re-exports types from this directory and adds the pipeline:

- `analyzeModule(...)` — lex / parse / validate comptime purity / infer
- `evaluateComptime(...)` — run script via runtime, parse JSON output
- `transform.transform(...)` — full AST rewrite
- `ComptimeSession` — owns shared arena + per-module `ComptimeOutput`

## Transform pass

```text
typed AST ──► Aggregator ──► transformed AST ──► codegen
```

`Aggregator`:

| Method | Role |
|---|---|
| `trackCall(fn_name)` | Counts a call to a fn with comptime params. |
| `trackSpecialization(fn_name)` | Counts a call rewritten to a mangled name. |
| `isFullySpecialized(fn_name)` | True if **all** calls were rewritten (original is dead). |

Steps:

1. **Scan** — find calls with comptime args, run `specialize()` → `SpecializedFn`.
2. **Rewrite** — `scale(2, base)` → `scale_$0(base)` (mangled, comptime arg dropped).
3. **Inline** — `val x = comptime expr` → `val x = <resolved>`.
4. **Filter** — drop originals where all calls were specialized.
5. **Inject** — add specialized `FnDecl` nodes to `program.decls`.

## Testing helpers

```zig
try assertTypes(alloc, source, &.{ .{ "x", "i32" }, .{ "f", "fn(i32) i32" } });
try assertTypeErrorSnap(alloc, @src(), source);
```

## Children

- [`runtime/AGENTS.md`](runtime/AGENTS.md) — Node.js + Erlang external eval.
