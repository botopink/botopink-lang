# core/src/comptime

Hindley-Milner type inference, comptime evaluation, and AST transformation for specialization.

## Files

| File | Role |
|---|---|
| `types.zig` | Core `Type` struct — union(enum) for all type representations |
| `env.zig` | `Env` — type environment (binding name → `*Type`); handles builtins + stdlib |
| `infer.zig` | `inferProgramTyped` — walks AST, infers types, returns `[]TypedBinding` |
| `unify.zig` | Unification algorithm for type variables |
| `error.zig` | `TypeError` — structured type errors with source locations + comptime validation |
| `eval.zig` | Comptime expression evaluation via external runtimes |
| `render.zig` | Comptime value rendering to target literals |
| `snapshot.zig` | Comptime snapshot utilities |
| `specialize.zig` | Pure AST specialization: `SpecializedFn`, `SpecCache`, `specialize()` — transforms function bodies for comptime args (loop unrolling, static if/case folding) |
| `transform.zig` | AST rewrite pass: `Aggregator` tracks calls, specializes, rewrites callee names, removes comptime args, inlines comptime vals, removes fully-specialized original functions |
| `tests.zig` | Tests via `assertTypes` and `assertTypeErrorSnap` |

## Runtime backends

| File | Role |
|---|---|
| `runtime/node.zig` | Node.js comptime runtime — evaluates JS and parses JSON output |
| `runtime/erlang.zig` | Erlang comptime runtime — evaluates Erlang scripts via `json:encode/1` |

## Testing helpers

- `assertTypes(allocator, source, &.{.{"name", "Type"}, ...})` — checks inferred types
- `assertTypeErrorSnap(allocator, @src(), source)` — snapshot-matches the rendered error

## Parent module

The parent `../comptime.zig` file re-exports types from this directory and
provides the target-agnostic `compile` pipeline:
- `analyzeModule()` — lex, parse, validate comptime purity, infer types
- `evaluateComptime()` — build Node.js eval script, run it, parse JSON results
- `transform.transform()` — rewrites AST: specializes calls, inlines comptime vals, removes dead code
- `ComptimeSession` — owns shared arena + per-module `ComptimeOutput` (includes transformed program)

## Transform pipeline

```
typed AST → transform (Aggregator) → transformed AST → codegen
```

### `Aggregator` struct

| Method | Role |
|---|---|
| `trackCall(fn_name)` | Counts a call to a fn with comptime params |
| `trackSpecialization(fn_name)` | Counts a call that was rewritten to a mangled name |
| `isFullySpecialized(fn_name)` | Returns true when ALL calls to fn were rewritten (original is dead code) |

### What transform does

1. **Scan** — finds calls with comptime args, calls `specialize()` to generate `SpecializedFn`
2. **Rewrite** — rewrites callee names (`scale(2, base)` → `scale_$0(base)`), removes comptime args from call arg lists
3. **Inline** — replaces `val x = comptime expr` with `val x = <resolved_value>` (e.g. `val pi = 6.28;`)
4. **Filter** — removes original functions where ALL calls were specialized (dead code)
5. **Inject** — adds specialized `FnDecl` nodes to the program

## Conventions

See `../AGENTS.md` for core architecture and testing guidelines. Type errors are
rendered via the structured error system in `error.zig` with source locations
and contextual hints.
