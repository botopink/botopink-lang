# language-server/src — internal architecture

> Path: `modules/language-server/src/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../docs.md`](../docs.md)

Layered architecture of the language server. Each layer has one job and
must not leak responsibilities into the others.

## Tree

```text
src/
├── main.zig           ← process entry — constructs and runs Server
├── server.zig         ← JSON-RPC message loop + LSP method dispatch
├── messages.zig       ← frame parser/writer (Content-Length protocol)
├── protocol.zig       ← LSP + JSON-RPC serializable types
├── engine.zig         ← LSP feature implementations
├── compiler.zig       ← thin wrapper around compiler-core for LSP analysis
├── files.zig          ← in-memory cache for open document contents
├── feedback.zig       ← tracks active diagnostics → clears stale editor feedback
├── lsp_types.zig      ← position/offset, URI ↔ path helpers
├── test_root.zig      ← aggregates every test module
└── tests/             ← feature-level tests
```

## Layer diagram

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

## Boundary rules

These are not stylistic preferences — violating them creates cascading
maintenance debt:

| Layer | Allowed to call | Forbidden |
|---|---|---|
| `messages.zig` | `std.io`, `std.json` | Nothing in `engine.zig` or `compiler.zig` |
| `protocol.zig` | `std.json` only | No feature logic, no compiler imports |
| `engine.zig` | `compiler.zig`, `files.zig`, `feedback.zig`, `lsp_types.zig`, protocol types | `@import("botopink")` directly |
| `compiler.zig` | `@import("botopink")` | Reading/writing LSP messages |
| `files.zig` | `std.fs`, `std.heap` | LSP types — it stores raw text |
| `feedback.zig` | `compiler.zig` for diagnostics | Anything from `messages.zig` |

The wrapping layers (`messages.zig`, `protocol.zig`) must stay passive.
If you see protocol code performing analysis, that's a refactor target.

## Document lifecycle

```text
textDocument/didOpen    → files.put(uri, content)
textDocument/didChange  → files.update(uri, content)
textDocument/didClose   → files.drop(uri)

(any feature request)   → files.get(uri) → compiler.analyze(...) → engine builds response
```

`files.zig` is the **single source of truth** for in-memory document
content. Don't read the filesystem from `engine.zig` — go through the
cache.

## Failure policy

When a request payload is unsupported, malformed, or addresses a closed
document, **return a graceful `null` response**. Never panic. The editor
will move on; a crash would tear down the whole session.

For internal errors (bug in the engine), log to stderr and respond with a
JSON-RPC error code. The editor surfaces this to the user.

## Adding a new LSP method

1. Add the LSP type to `protocol.zig` if it isn't there yet.
2. Add a handler arm to `engine.zig` (`fn handleHover`, `fn handleRename`,
   …).
3. Wire it into `server.zig`'s dispatch `switch`.
4. Add a feature test in [`tests/`](tests/AGENTS.md) — one file per
   feature is the convention.
5. Add a snapshot under [`../snapshots/lsp/`](../snapshots/lsp/AGENTS.md)
   using the standard prefix (`hover_*`, `rename_*`, …).

## See also

- LSP feature surface → [`../docs.md`](../docs.md).
- Test harness → [`tests/AGENTS.md`](tests/AGENTS.md).
- Compiler API consumed by `compiler.zig` →
  [`../../compiler-core/docs.md`](../../compiler-core/docs.md).
