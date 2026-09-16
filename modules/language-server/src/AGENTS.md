# language-server/src

> Path: `modules/language-server/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../AGENTS.md`](../../../AGENTS.md)

JSON-RPC server, protocol types, feature engine and test harness.

## Tree

```text
src/
├── AGENTS.md          ← you are here
├── main.zig           ← process entry — constructs and runs Server
├── server.zig         ← JSON-RPC message loop + LSP method dispatch
├── messages.zig       ← frame parser/writer (Content-Length protocol)
├── protocol.zig       ← LSP + JSON-RPC serializable types
├── engine.zig         ← LSP feature implementations
├── compiler.zig       ← thin wrapper around compiler-core (`LspCompiler`, `CompileResult`)
├── files.zig          ← in-memory cache for open document contents
├── feedback.zig       ← tracks active diagnostics → clears stale editor feedback
├── lsp_types.zig      ← position/offset, URI ↔ path helpers
├── project_index.zig  ← lazy project-wide pub symbol index (cross-module features)
├── project_graph.zig  ← per-project dependency graph (libs + mod siblings) for the project-graph compile
├── test_root.zig      ← test aggregator used by both build.zig files
└── tests/             ← feature-level tests — see tests/AGENTS.md
```

## Layered design

```text
main.zig
  └─ server.zig         ← JSON-RPC dispatch
        ├─ messages.zig ← transport
        ├─ protocol.zig ← types
        ├─ project_graph.zig / project_index.zig
        └─ engine.zig   ← feature impl
              ├─ compiler.zig
              ├─ files.zig
              ├─ feedback.zig
              └─ lsp_types.zig
```

Keep these boundaries strict:

- **Transport** (`messages.zig`) and **protocol** (`protocol.zig`) must not
  contain feature logic.
- **Feature logic** belongs in `engine.zig`; use `compiler.zig` to call into
  compiler-core's compile pipeline.
- Return a graceful null response when a request payload is unsupported or
  malformed — don't panic.

When adding a new LSP method: add the dispatch arm in `server.zig`, implement it
in `engine.zig`, add a test in [`tests/`](tests/AGENTS.md) (register it in
`test_root.zig`) and a snapshot under `../snapshots/lsp/`.

## Gotchas

- `protocol.zig`'s `SemanticTokenTypes` / `SemanticTokenModifiers` indices **are**
  the legend advertised to the client. Append only — never reorder, and extend
  the matching `legend` array in the same edit (`async`, bit 3, is the newest
  modifier: it marks effect fns).
- `engine.documentSymbols` returns owned names **and owned children**; free a
  result with `engine.freeSymbol` per symbol, never `gpa.free(sym.name)` alone,
  or every child leaks.
- `semanticTokens` is a single token walk with a little state: `fn_params` /
  `fn_generics` (names in scope for the body being scanned, cleared when it
  closes), `generic_depth` (only a `<` right after a *declaration name* opens a
  type-parameter list — everywhere else `<` stays a comparison), and
  `pending_effect_fn` (set by `*` or a `#[@effect]` attribute before the `fn`).
