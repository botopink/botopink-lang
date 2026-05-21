# compiler-core/src

> Path: `modules/compiler-core/src/`
> Parent: [`../AGENTS.md`](../AGENTS.md) · Root: [`../../../AGENTS.md`](../../../AGENTS.md)

All compiler stages live here. Each top-level `*.zig` is a façade; the
implementation typically delegates to a sibling directory of the same name.

## Tree

```text
src/
├── AGENTS.md             ← you are here
├── root.zig              ← public library entry (re-exports the public API)
├── main.zig              ← minimal CLI stub used by `zig build run`
├── test_root.zig         ← aggregates all test files
├── module.zig            ← `Module` struct — input module representation
├── ast.zig               ← AST node types (categorised: literal/binaryOp/jump/branch/loop/binding/call/function/collection/comptime_)
├── lexer.zig             ← Lexer (delegates to lexer/token.zig)
├── parser.zig            ← Recursive-descent parser
├── format.zig            ← Wadler-Lindig pretty printer (round-trip stable)
├── print.zig             ← rustc-style diagnostics renderer
├── comptime.zig          ← Target-agnostic comptime façade: `ComptimeSession`, `compile`, `evaluateComptime`
├── codegen.zig           ← Public codegen API: `compile`, `codegenEmit`, `generate`
├── codegen/              ← Per-target backends — see codegen/AGENTS.md
├── comptime/             ← HM inference + comptime transform — see comptime/AGENTS.md
│   └── runtime/          ← External eval scripts (Node.js + Erlang)
├── lexer/                ← Token struct + lexer snapshot tests
├── parser/               ← Parser snapshot tests
├── format/               ← Formatter snapshot tests
└── utils/                ← Snapshot/JSON helpers — see utils/AGENTS.md
```

## Top-level façades

| File | Role |
|---|---|
| `root.zig` | Library entry point — re-exports the public API. |
| `main.zig` | Minimal CLI stub (used by `zig build run`). |
| `ast.zig` | All AST node types (`union(enum)` throughout); both untyped and typed phases. |
| `lexer.zig` | Lexer façade — delegates to `lexer/token.zig`. |
| `parser.zig` | Recursive-descent parser. `init(tokens)` does **not** store an allocator. |
| `module.zig` | `Module` — input module representation. |
| `comptime.zig` | Target-agnostic comptime — `ComptimeSession`, `compile`, `evaluateComptime`. |
| `format.zig` | Wadler-Lindig pretty-printer. Must be round-trip stable. |
| `print.zig` | rustc-style error renderer (caret + position + hint). |
| `codegen.zig` | Public codegen API. Dispatches to `codegen/<target>.zig`. |

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

## Pipeline at this level

```text
lex → parse → infer → transform (Aggregator rewrites AST) → codegen (blind emit)
```

1. **lex / parse** — source → typed AST
2. **infer** — Hindley–Milner type inference (`comptime/infer.zig`)
3. **transform** — `comptime/transform.zig` `Aggregator` scans for comptime
   calls, generates specialized `FnDecl` nodes, rewrites callees to mangled
   names, removes comptime args, inlines comptime vals, drops dead originals
4. **codegen** — `codegen/commonJS.zig` or `codegen/erlang.zig`: blind emit
   from the transformed AST

## Conventions

- **Allocator pattern**: never store `allocator` as a struct field. Always
  pass it as `alloc: std.mem.Allocator` to the method that needs it.
  Emitters (internal) may keep an `alloc` field but it must arrive via `init`.
- Helpers worth knowing about in the parser:
  - `boxExpr(alloc, expr)` — heap-allocate an `Expr` pointer
  - `parseStmtListInBraces(alloc)` — parse `{ stmt; … }` blocks
  - `parseCommaSeparatedIdentifiers(alloc, stopAt)`
  - `reportReservedWordError()` — centralised reserved-word error
- Type annotations always use `TypeRef`
  (`named`, `array`, `tuple_`, `optional`, `errorUnion`, `function`).
- Formatter must round-trip: `format(parse(src))` must re-parse to an
  equivalent AST.

## Current-release highlights (v0.0.13-beta)

- Pipeline `|>` (`ExprKind.pipeline`) — left-associative.
- Anonymous function expression `fn(params) { body }` (`ExprKind.fnExpr`).
- Parenthesised expression (`ExprKind.grouped`).
- `CaseArm.emptyLineBefore` preserves blank lines between arms.
- `ArrayLit.trailingComma` forces multi-line array formatting.
- `Param.typeRef` replaces raw `typeName: []const u8`.
- Lexer: `1_000_000` digit separators, scientific notation, unary `-` in primary.
