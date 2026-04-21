# Plan: modules/language-server

Reference: `gleam/language-server` (Rust) → botopink LSP (Zig)

---

## Overview

The language server implements the **Language Server Protocol (LSP)** over
`stdin/stdout` (JSON-RPC 2.0), allowing any compatible editor
(VSCode, Neovim, Helix, Zed…) to consume real-time analysis of botopink code.

All compilation logic already exists in `compiler-core`:

| LSP Feature             | compiler-core API used                                 |
|-------------------------|--------------------------------------------------------|
| Diagnostics             | `comptime_pipeline.compileTypesOnly()` → `ComptimeOutput` |
| Formatting              | `format.format(alloc, program)`                        |
| Hover (type)            | `compileTypesOnly` → `TypedBinding` / `Type`           |
| Go to definition        | `Lexer` → token scan for declaration keyword + name    |
| Document symbols        | `Lexer` → token scan for declaration keywords          |
| Completion              | `compileTypesOnly` → `TypedBinding` slice (Phase 3)    |
| Parse errors            | `Parser.parseError` → `ParseErrorInfo`                 |

---

## File structure

```
modules/language-server/
├── build.zig
├── build.zig.zon          ← depends on ../compiler-core
└── src/
    ├── main.zig           ← entry point: init Server and run loop
    ├── server.zig         ← LSP handshake, message loop, dispatch
    ├── engine.zig         ← LSP feature implementations
    ├── compiler.zig       ← incremental compilation wrapper (compileTypesOnly)
    ├── files.zig          ← in-memory cache of unsaved edits
    ├── feedback.zig       ← tracks which files have active diagnostics
    ├── messages.zig       ← JSON-RPC 2.0 frame reader/writer
    ├── protocol.zig       ← LSP types (JSON-serializable structs)
    └── lsp_types.zig      ← conversions: src_span ↔ LSP Range/Position
```

---

## LSP Protocol (JSON-RPC 2.0)

Messages arrive via **stdin**, responses leave via **stdout**.

Frame format:
```
Content-Length: <N>\r\n
\r\n
<N bytes of JSON>
```

`messages.zig` handles:
1. Reading the `Content-Length` header
2. Reading exactly N bytes of body
3. `std.json.parseFromSlice` → `JsonRpcMessage`
4. Returning as `Request`, `Response`, or `Notification`

---

## Server lifecycle

```
main()
  server = Server.init(gpa, io)
  server.run()          ← loop until shutdown received
```

### Handshake (initialize / initialized)

```
← initialize (client sends capabilities)
→ InitializeResult (server announces capabilities)
← initialized (notification, no response)
```

---

## Module `compiler.zig` — type-only compilation

Uses `comptime_pipeline.compileTypesOnly()` instead of `compile()`:
- Runs lex + parse + type inference
- **Skips** `evaluateComptime()` — no external runtime spawned
- Safe and fast for use during editing

The `.none` Runtime variant does **not** exist. The separation is
enforced at the API level: `compileTypesOnly` never calls `evaluate()`.

---

## Module `engine.zig` — LSP features

### Diagnostics
- `compileTypesOnly` → `validationError` outcomes → `Diagnostic` (severity: Error)
- `Parser.parseError` → parse errors → `Diagnostic`
- Published via `textDocument/publishDiagnostics`

### Formatting
```
source → Lexer.scanAll → Parser.parse → format.format →
  single TextEdit covering the whole document
```

### Hover
```
cursor position → scan source for identifier at offset →
  match against TypedBinding names → renderType →
  return MarkupContent (Markdown)
```

### Go to Definition
```
cursor position → identifier name →
  scan tokens for keyword (val/fn/record/struct/enum/interface) + name →
  return Location (uri + range of name token)
```

### Document Symbols
```
scan tokens for declaration keywords + following identifier →
  emit DocumentSymbol for each (Function/Variable/Struct/Enum/Interface)
```

---

## Implementation phases

### Phase 1 — Core (✅ done)

| # | What | File |
|---|------|------|
| 1 | JSON-RPC frame reader/writer | `messages.zig` |
| 2 | LSP types + serialization | `protocol.zig` |
| 3 | initialize / shutdown handshake | `server.zig` |
| 4 | Open file cache | `files.zig` |
| 5 | Diagnostics on open/change | `engine.zig` + `feedback.zig` |
| 6 | Document formatting | `engine.zig` |

### Phase 2 — Navigation (✅ done)

| # | What | File |
|---|------|------|
| 7 | Hover with inferred type | `engine.zig` |
| 8 | Go to definition | `engine.zig` |
| 9 | Document symbols | `engine.zig` |

### Phase 3 — Completions and refactors (✅ done)

| # | What | File |
|---|------|------|
| 10 | Basic completion (bindings in scope) | `engine.zig` |
| 11 | Local rename | `engine.zig` |
| 12 | Find references | `engine.zig` |

### Phase 4 — Code Intelligence (✅ done)

| # | What | File |
|---|------|------|
| 14 | Signature help (active parameter highlight) | `engine.zig` |
| 15 | Inlay hints (inferred types inline) | `engine.zig` |
| Fix | Memory leak in writeRenameResponse | `server.zig` |

---

## Dependencies added to compiler-core

1. **`compileTypesOnly(gpa, modules)`** — lex + parse + type inference, skips
   `evaluateComptime`. Added to `comptime.zig`.

2. **`Token`, `TokenKind`** — re-exported from `root.zig` so consumers don't
   need to import `lexer.zig` directly.

3. **`Type`** — re-exported via `comptime_pipeline.Type` from `comptime.zig`.

---

## Notes

- The LSP is a separate process from the compiler; editors start it via
  `"botopink-lsp"` in PATH.
- stdin/stdout are the transport channel; no socket needed.
- Single-threaded event loop — safe because `compileTypesOnly` is pure
  (no external process spawning).
- The `compileTypesOnly` API guarantees `.none` runtime is never needed:
  the separation is structural, not a flag.

✻ Escrevendo messages.zig… (42s · ↑ 1.6k tokens · thought for 4s)
  ⎿  ✔ Criar protocol.zig e lsp_types.zig
     ◼ Criar messages.zig
     ◻ Criar files.zig, feedback.zig, compiler.zig
     ◻ Criar engine.zig e server.zig
     ◻ Criar main.zig, build.zig, build.zig.zon
     ◻ Compilar e corrigir erros