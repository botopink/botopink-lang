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
    └── lsp/           ← 88 LSP feature snapshots
```

## What the server supports

The server currently handles `initialize` / `shutdown` plus these
`textDocument/*` methods:

| Capability | Notes |
|---|---|
| `publishDiagnostics` | Driven by `feedback.zig`; clears stale messages between compiles; sends `$/progress` begin/end. Surfaces parse errors, comptime-validation errors, **and located type-inference errors** (the `typeError` outcome) |
| `formatting` | Calls `botopink.format` — same code path as `botopink format` |
| `hover` | Full signature (fn with params/return, record with fields, enum with variants) + `///` doc comments; on a qualified std member (`list.map`, `io.println`) renders the `pub [declare] fn` signature read from the embedded std source, tagged `from std/<module>`; on a builtin interface method (`n.abs`, `true.to_string`, `xs.map`) renders the method signature tagged `from interface <Name>` |
| `definition` | Jumps to the declaration of the symbol; on a local miss, resolves **imported symbols** to their `pub` declaration in another module (`definitionInModules`, candidate sources gathered from the project index); on a workspace miss, resolves **std module symbols** (`list.map`, bare `list`) against the embedded "std" package (`definitionInStdModules`) and materializes the module source under `~/.cache/botopink-lsp/std/` |
| `typeDefinition` | Jumps to the type declaration (record/struct/enum) of the symbol |
| `documentSymbol` | Hierarchical outline: enum variants, struct/record fields, methods nested under parent; `test "name" { … }` blocks surface as `Method` symbols |
| `completion` | Identifiers + dot-completion of members (trigger `.`) — fields/methods of a value receiver **and** variants/fields of a type-name receiver (`Status.`, `Point.`) — + std module members on `list.`/`io.` (the module's `pub fn`s, when imported from "std") + **builtin interface methods** on primitive/array/string receivers (`n.`, `true.`, `xs.`, `"s".`, read from the embedded `primitives.d.bp`/`array.d.bp`/`string.d.bp`) + labeled args + type-aware sorting + module name completion (inside `from "…"`) |
| `references` | Lists references in current file + re-lexes external files for exact positions via project index |
| `rename` | Cross-module rename with `prepareRename` validation (multi-file WorkspaceEdit, rejects keywords/literals) |
| `signatureHelp` | Active parameter highlighting on function calls (trigger `(`, retrigger `,` `:`); on a builtin interface method (`n.clamp(`) the receiver's `self` parameter is dropped |
| `inlayHint` | Inferred type after `val x = …` (suppressed when annotated); parameter-name hints before call arguments (skipped for bare-name / already-named args); lambda parameter-type hints from the callee's `fn(…)` signature. A `workspace/inlayHint/refresh` request is sent on every edit |
| `semanticTokens` | `full` + `range`; token-driven classifier (legend: `type`/`interface`/`enum`/`enumMember`/`function`/`method`/`parameter`/`variable`/`property`/`keyword`/`comment` + `declaration`/`readonly`/`defaultLibrary`). Distinguishes builtin `@Type`s (`@Result`/`@Option`/`@Iterator` → `type defaultLibrary`), interface/struct methods (`method`) vs free fns (`function`), the `*` effect marker of `*fn`, comptime params (`parameter readonly`), and enum members. Survives type errors (lexer always runs; bindings are best-effort) |
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

- **Add missing import** code action — suggests `import { X } from "module"`
- **Module name completion** — inside `import { … } from "…"` strings
- **Cross-module references** — finds symbol declarations in other files
- **Go-to-definition on imported symbols** — supplies the candidate module sources that
  `definitionInModules` scans for a matching `pub` declaration

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
