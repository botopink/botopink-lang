# core/src/codegen

## Files

| File | Role |
|---|---|
| `config.zig` | Configuration: `Config`, `Target` (commonJS | erlang), `ComptimeRuntime`, `TypeDefLang` |
| `moduleOutput.zig` | Shared types: `Module`, `ModuleOutput`, `GenerateResult` |
| `commonJS.zig` | CommonJS backend — **blind emitter**: iterates transformed `ast.Program` and renders to JS. No specialization logic. |
| `erlang.zig` | Erlang backend — **blind emitter**: iterates transformed `ast.Program` and renders to Erlang. No specialization logic. |
| `typescript.zig` | TypeScript type definition generator |
| `snapshot.zig` | Snapshot test helpers |
| `tests.zig` | Snapshot test harness (`assertJs`, `assertJsSingle`, `assertJsError`) |

## Design principle: Emitter is blind

The CommonJS emitter knows nothing about comptime specialization. It only:
- Iterates `program.decls` from the **transformed** AST
- Renders each `DeclKind` to JavaScript
- Comptime vals that were inlined appear as `const x = 6.28;` (resolved by the transform)
- Specialized functions (`scale_$0`) are already present as regular `DeclKind.fn` nodes
- Calls are already rewritten to mangled names with comptime args removed

All specialization work happens in `../comptime/transform.zig` before codegen runs.

## Pipeline (`codegen.generate`)

```
compile(allocator, modules, io, config)   — lex, parse, infer, transform
  └─→ ComptimeSession (owns arena + per-module transformed programs)

codegenEmit(allocator, outputs, config)   — blind emit based on config.target
  ├─ commonJS: emitProgram(transformed_ast, comptime_vals) → JS source
  ├─ erlang: emitProgram(transformed_ast, comptime_vals) → Erlang source
  └─ typescript: generateTypedefs(bindings) → .d.ts source
```

## Snapshots

`../../snapshots/codegen/<slug>.snap.md` — multi-section format:

```
----- SOURCE CODE -- main.bp
...

----- COMPTIME JAVASCRIPT
...  (empty when no comptime exprs)

----- JAVASCRIPT -- main.js
...

----- TYPESCRIPT TYPEDEF -- main.d.ts   (when configured)
```

Error snapshots live under `../../snapshots/codegen/errors/`.

## Conventions

See `../../AGENTS.md` for core architecture. No separate Node.js or Wasm modules — JS and Erlang are emitted natively in Zig.
Comptime evaluation and specialization are handled by `../comptime.zig` and `../comptime/transform.zig` (target-agnostic), not by this package.
