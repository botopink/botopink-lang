# core/src

## Files at this level

| File | Role |
|---|---|
| `root.zig` | Library entry point — exports the public API |
| `main.zig` | CLI stub (currently minimal) |
| `ast.zig` | All AST node types (`union(enum)` throughout) |
| `lexer.zig` | Lexer entry point — delegates to `lexer/token.zig` |
| `parser.zig` | Recursive-descent parser |
| `module.zig` | `Module` struct — input module representation |
| `comptime.zig` | Target-agnostic comptime compilation: `ComptimeSession`, `compile`, `evaluateComptime` |
| `format.zig` | Wadler-Lindig pretty-printer (`ast.Program → formatted source`) |
| `print.zig` | rustc-style error renderer (position + hint lines) |
| `codegen.zig` | Public codegen API — dispatches to target-specific backends, re-exports `ComptimeSession` from `comptime.zig` |

## Subdirectories

| Dir | Files |
|---|---|
| `lexer/` | `token.zig` (token definitions), `tests.zig` (snapshot tests) |
| `parser/` | `tests.zig` (parser snapshot tests) |
| `comptime/` | Type inference + comptime compilation: `types.zig`, `env.zig`, `infer.zig`, `unify.zig`, `error.zig`, `eval.zig`, `render.zig`, `snapshot.zig`, `tests.zig`, **`transform.zig`** (AST rewrite pass for specialization), **`specialize.zig`** (pure AST specialization), `runtime/` (Node.js + Erlang comptime runtimes) |
| `codegen/` | `config.zig` (configuration), `moduleOutput.zig` (output types), `commonJS.zig` (CommonJS backend), `erlang.zig` (Erlang backend), `typescript.zig` (TypeScript typedefs), `snapshot.zig` (snapshot helpers), `tests.zig` (codegen tests) |
| `format/` | `tests.zig` (formatter snapshot tests) |
| `utils/` | `snap.zig` (snapshot infrastructure), `pretty.zig` (JSON serialization), `json_diff.zig` (JSON diff output) |

## Pipeline

```
lex → parse → infer types → transform (Aggregator rewrites AST) → codegen (blind emitter) → target
```

### Phases

1. **lex/parse** — source → typed AST
2. **infer** — Hindley-Milner type inference
3. **transform** (`comptime/transform.zig`) — `Aggregator` scans for comptime calls, generates specialized `FnDecl` nodes, rewrites calls to mangled names, removes comptime args, inlines comptime values, removes fully-specialized original functions
4. **codegen** (`codegen/commonJS.zig` or `codegen/erlang.zig`) — blind emitter, only iterates `program.decls` and renders to target language
