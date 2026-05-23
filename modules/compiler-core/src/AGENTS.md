# compiler-core/src

> Path: `modules/compiler-core/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../AGENTS.md`](../../../AGENTS.md)
> Docs: [`./docs.md`](docs.md)

All compiler stages live here. Each top-level `*.zig` is a façade; the
implementation delegates to a sibling directory of the same name.

## Tree

```text
src/
├── AGENTS.md             ← you are here
├── docs.md               ← detailed architecture: façade pattern, pipeline, conventions
├── root.zig              ← public library entry (re-exports the public API)
├── main.zig              ← minimal CLI stub used by `zig build run`
├── test_root.zig         ← aggregates all test files
├── module.zig            ← `Module` struct — input module representation
├── ast.zig               ← AST node types (categorised)
├── lexer.zig             ← Lexer (delegates to lexer/token.zig)
├── parser.zig            ← Recursive-descent parser
├── format.zig            ← Wadler-Lindig pretty printer (round-trip stable)
├── print.zig             ← rustc-style diagnostics renderer
├── comptime.zig          ← Target-agnostic comptime façade
├── codegen.zig           ← Public codegen API
├── codegen/              ← Per-target backends — see codegen/AGENTS.md
├── comptime/             ← HM inference + transform — see comptime/AGENTS.md
│   └── runtime/          ← External eval scripts (Node.js + Erlang)
├── lexer/                ← Token struct + lexer snapshot tests
├── parser/               ← Parser snapshot tests
├── format/               ← Formatter snapshot tests
└── utils/                ← Snapshot/JSON helpers
```

## Top-level façades

| File | Role | Deeper docs |
|---|---|---|
| `root.zig` | Library entry — re-exports public API | — |
| `ast.zig` | All AST node types | [`./docs.md`](docs.md) |
| `lexer.zig` | Lexer façade → `lexer/token.zig` | [`lexer/docs.md`](lexer/docs.md) |
| `parser.zig` | Recursive-descent parser | [`parser/docs.md`](parser/docs.md) |
| `comptime.zig` | Comptime façade — `ComptimeSession`, `compile`, `evaluateComptime` | [`comptime/docs.md`](comptime/docs.md) |
| `format.zig` | Wadler-Lindig formatter | [`format/docs.md`](format/docs.md) |
| `print.zig` | rustc-style error renderer | — |
| `codegen.zig` | Public codegen API | [`codegen/docs.md`](codegen/docs.md) |

## Subdirectories

| Dir | Purpose | AGENTS |
|---|---|---|
| `lexer/` | `token.zig` + tests | [link](lexer/AGENTS.md) |
| `parser/` | parser snapshot tests | [link](parser/AGENTS.md) |
| `format/` | formatter snapshot tests | [link](format/AGENTS.md) |
| `comptime/` | HM types, infer, unify, transform, specialize, eval | [link](comptime/AGENTS.md) |
| `comptime/runtime/` | Node.js + Erlang comptime runtimes | [link](comptime/runtime/AGENTS.md) |
| `codegen/` | per-target backends (commonJS, erlang, typescript) | [link](codegen/AGENTS.md) |
| `utils/` | snap.zig, pretty.zig, json_diff.zig | [link](utils/AGENTS.md) |

## Dir-specific conventions

- **Allocator pattern** — never store `allocator` as a struct field. Pass
  `alloc: std.mem.Allocator` to the method that needs it. Emitters may keep
  an `alloc` field but it must arrive via `init`.
- **Parser helpers** to know about — `boxExpr`, `parseStmtListInBraces`,
  `parseCommaSeparatedIdentifiers`, `reportReservedWordError`.
- **Type annotations** always use `TypeRef`.
- **Formatter** must round-trip: `format(parse(src))` must re-parse to an
  equivalent AST.

For pipeline details, façade pattern rationale, and current-release
highlights see [`./docs.md`](docs.md).
