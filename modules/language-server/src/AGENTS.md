# language-server/src

> Path: `modules/language-server/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../AGENTS.md`](../../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

JSON-RPC server, protocol types, feature engine and test harness.

## Tree

```text
src/
├── AGENTS.md          ← you are here
├── docs.md            ← layered architecture + boundary rules
├── main.zig           ← process entry — constructs and runs Server
├── server.zig         ← JSON-RPC message loop + LSP method dispatch
├── messages.zig       ← frame parser/writer (Content-Length protocol)
├── protocol.zig       ← LSP + JSON-RPC serializable types
├── engine.zig         ← LSP feature implementations
├── compiler.zig       ← thin wrapper around compiler-core for LSP analysis
├── files.zig          ← in-memory cache for open document contents
├── feedback.zig       ← tracks active diagnostics → clears stale editor feedback
├── lsp_types.zig      ← position/offset, URI ↔ path helpers
├── project_index.zig  ← lazy project-wide pub symbol index (powers cross-module features)
├── project_graph.zig  ← per-project dependency graph (libs + mod siblings) for the project-graph compile
├── test_root.zig      ← aggregates every test module
└── tests/             ← feature-level tests — see tests/AGENTS.md
    └── docs.md
```

## Layered design

```text
main.zig
  └─ server.zig         ← JSON-RPC dispatch
        ├─ messages.zig ← transport
        ├─ protocol.zig ← types
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
  compiler-core, never `@import("botopink")` directly elsewhere.
- Return a graceful null response when a request payload is unsupported or
  malformed — don't panic.

When adding a new LSP method: extend `engine.zig`, add a test in
[`tests/`](tests/AGENTS.md) and a snapshot under
[`../snapshots/lsp/`](../snapshots/lsp/AGENTS.md).
