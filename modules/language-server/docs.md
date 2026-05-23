# language-server — `botopink-lsp` reference

> Path: `modules/language-server/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../docs.md`](../docs.md)

Detailed reference for the `botopink-lsp` executable — the editor-facing
language server. Wraps `compiler-core` and speaks LSP over JSON-RPC.

## Tree

```text
language-server/
├── build.zig          ← build graph (`run`, `test`)
├── build.zig.zon      ← deps (compiler-core)
├── src/               ← server + protocol + features + tests
└── snapshots/
    └── lsp/           ← 66 LSP feature snapshots
```

## What the server supports

The server currently handles `initialize` / `shutdown` plus these
`textDocument/*` methods:

| Capability | Notes |
|---|---|
| `publishDiagnostics` | Driven by `feedback.zig`; clears stale messages between compiles; sends `$/progress` begin/end |
| `formatting` | Calls `botopink.format` — same code path as `botopink format` |
| `hover` | Full signature (fn with params/return, record with fields, enum with variants) + `///` doc comments |
| `definition` | Jumps to the declaration of the symbol |
| `typeDefinition` | Jumps to the type declaration (record/struct/enum) of the symbol |
| `documentSymbol` | Hierarchical outline: enum variants, struct/record fields, methods nested under parent |
| `completion` | Identifiers + dot-completion of members (trigger `.`) + labeled args + type-aware sorting + module name completion (inside `from "…"`) |
| `references` | Lists references in current file + re-lexes external files for exact positions via project index |
| `rename` | Cross-module rename with `prepareRename` validation (multi-file WorkspaceEdit, rejects keywords/literals) |
| `signatureHelp` | Active parameter highlighting on function calls (trigger `(`, retrigger `,` `:`) |
| `inlayHint` | Inferred binding types shown inline |
| `codeAction` | "Add type annotation"; "Remove unused import"; "Add missing case patterns"; "Import 'X' from module" (via project index) |
| `foldingRange` | Foldable regions for `fn`/`struct`/`record`/`enum`/`interface`/`implement` blocks and consecutive `use` imports |

Add a new feature → implement it in
[`src/engine.zig`](src/docs.md), add a test under
[`src/tests/`](src/tests/AGENTS.md), and a snapshot under
[`snapshots/lsp/AGENTS.md`](snapshots/lsp/AGENTS.md).

## Transport: JSON-RPC over stdio

LSP messages arrive as `Content-Length: N\r\n\r\n{json…}` frames. The
framing parser lives in `src/messages.zig`; the LSP-specific types
(`InitializeParams`, `Diagnostic`, `Position`, …) live in
`src/protocol.zig`. Both layers are deliberately **passive** — they
don't perform any analysis. Feature logic only happens in `engine.zig`.

## Project index

`src/project_index.zig` maintains a lazy, invalidate-on-change index of all
`pub` symbols across `.bp` files in the workspace. It scans recursively from
the `rootUri` received during `initialize`, skipping hidden dirs,
`node_modules`, and `zig-cache`. The index powers:

- **Add missing import** code action — suggests `use { X } from "module"`
- **Module name completion** — inside `use ... from "…"` strings
- **Cross-module references** — finds symbol declarations in other files

The index is rebuilt lazily on first access after `didChange` invalidation.
No file watchers are needed — invalidation happens on every content change.

## Why a thin compiler wrapper

`src/compiler.zig` is the **only** module allowed to
`@import("botopink")` directly. Every other file calls into compiler-core
through this wrapper. This keeps protocol code free of compiler-internal
types and gives us one obvious place to add caching/reuse later.

## Local dev loop

```bash
# build the server
cd modules/language-server
zig build

# run over stdio (your editor launches this)
./zig-out/bin/botopink-lsp

# run tests + snapshots
zig build test
```

For editor integration the entry is `botopink-lsp` on stdio with no
arguments. Configure your editor to launch it for `.bp` files.

## See also

- Layered design + feature engine → [`src/docs.md`](src/docs.md).
- LSP feature test harness → [`src/tests/AGENTS.md`](src/tests/AGENTS.md).
- Underlying compiler API → [`../compiler-core/docs.md`](../compiler-core/docs.md).
